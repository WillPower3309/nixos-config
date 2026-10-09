{ config, inputs, lib, ... }:

let
  pkgs = inputs.nixpkgs.legacyPackages."x86_64-linux";
  # every microvm from modules/vms/ is scheduled on the cluster (see modules/microvms.nix)
  microvms = config.flake.microvms;
  vmSystems = lib.mapAttrs (name: _: (inputs.self.lib.mkNixos "x86_64-linux" name).${name}) microvms;
in {
  # Builds the nomad job spec (and the hypervisor script) that runs the microvm
  # Inspired by https://github.com/astro/skyflake/blob/main/nixos-modules/nomad-job.nix
  config.flake.lib.mkNomadJob = { name, vmSystem, vfs, constraints }:
    let
      seconds = s: s * 1000000000; # nomad API durations are in nanoseconds
      vm = vmSystem.config;
      # The VM's NICs are the VFs claimed below, added to qemu's args at runtime (microvm-run ignores its own
      # arguments) so the VM definition stays host-independent; `nix run .#<name>-vm` runs it without NICs.
      # note: qemu only enables PCIe, which the vfio-pci devices need, because of the guest's ro-store share
      vfioArgs = pkgs.writeShellScript "vfio-args" ''
        for addr in $MICROVM_VFIO_PCIS; do
          echo "-device vfio-pci,host=$addr"
        done
      '';
      runner = (vmSystem.extendModules {
        modules = [{ microvm.extraArgsScript = "${vfioArgs}"; }];
      }).config.microvm.runner.qemu;
      workDir = "/var/lib/microvms/${name}"; # holds volume images and the qemu control socket
      # runs as root to configure the VFs on their PF, then starts qemu as the microvm user
      hypervisor = pkgs.writeShellScript "${name}-hypervisor" ''
        set -e
        export PATH=${lib.makeBinPath [ pkgs.coreutils pkgs.util-linux pkgs.iproute2 ]}:$PATH
        install -d -o microvm -g kvm -m 0750 ${workDir}
        cd ${workDir}

        # A VF is claimed by holding a flock on its lock file, so two VMs starting at once can't both take (and
        # configure) the same one. The fds aren't close-on-exec, so qemu inherits them and the claim lasts as long
        # as the VM; the kernel releases it when the last holder exits, so a crashed VM never leaks a VF.
        mkdir -p /run/microvm-vfs
        claim_vf() {
          local addr fd
          for addr in $(cat /etc/microvm-vfs); do
            exec {fd}>"/run/microvm-vfs/$addr.lock"
            if flock -n "$fd"; then
              claimed=$addr
              return
            fi
            exec {fd}>&-
          done
          echo "No free VF on this node" >&2
          exit 1 # releases any VFs already claimed; nomad restarts, then reschedules the allocation
        }

        # set the VF's MAC and port VLAN (0 = none), overwriting whatever the last VM to use it left
        configure_vf() {
          local addr=$1 mac=$2 vlan=$3 fn idx= pf
          pf=$(ls /sys/bus/pci/devices/$addr/physfn/net)
          for fn in /sys/bus/pci/devices/$addr/physfn/virtfn*; do
            if [ "$(basename "$(readlink "$fn")")" = "$addr" ]; then idx=''${fn##*virtfn}; fi
          done
          ip link set dev "$pf" vf "$idx" mac "$mac" vlan "$vlan"
        }

        claimed_vfs=
        ${lib.concatMapStrings (vf: ''
          claim_vf
          configure_vf "$claimed" ${vf.mac} ${toString (if vf.vlan == null then 0 else vf.vlan)}
          claimed_vfs="$claimed_vfs $claimed"
        '') vfs}
        echo "Using VFs:$claimed_vfs" >&2

        MICROVM_VFIO_PCIS="$claimed_vfs" setpriv --reuid=microvm --regid=kvm --init-groups --inh-caps=-all \
          ${runner}/bin/microvm-run &
        pid=$!

        # nomad sends SIGCONT (see KillSignal) so the guest can shut down cleanly
        shutdown() {
          echo "Received signal, shutting down" >&2
          ${runner}/bin/microvm-shutdown
          exit
        }
        trap shutdown CONT
        wait $pid # a bare `wait` always returns 0, hiding qemu failures from nomad
      '';
    in pkgs.writeText "${name}-nomad-job.json" (builtins.toJSON {
      Job = {
        ID = name;
        Name = name;
        Type = "service";
        Datacenters = [ "*" ];
        TaskGroups = [{
          Name = name;
          Count = 1;
          RestartPolicy = {
            Attempts = 3;
            Delay = seconds 3;
            Interval = seconds 60;
            Mode = "fail";
          };
          ReschedulePolicy = {
            Unlimited = true;
            Delay = seconds 90;
            DelayFunction = "constant";
          };
          Constraints = [
            { LTarget = "\${attr.kernel.arch}"; Operand = "="; RTarget = vm.nixpkgs.hostPlatform.uname.processor; }
            { LTarget = "\${attr.cpu.numcores}"; Operand = ">="; RTarget = toString vm.microvm.vcpu; }
          ] ++ map (constraint: {
            LTarget = constraint.attribute;
            Operand = constraint.operator;
            RTarget = constraint.value;
          }) constraints;
          Tasks = [{
            Name = "hypervisor";
            Driver = "raw_exec"; # as root (the agent's user), see hypervisor above
            Config.command = "${hypervisor}";
            Leader = true;
            KillSignal = "SIGCONT";
            KillTimeout = seconds 95; # leave the guest time to shut down
            Resources = {
              CPU = vm.microvm.vcpu * 500; # MHz reserved for scheduling
              MemoryMB = vm.microvm.mem + 256; # guest RAM + qemu overhead
            };
          }];
        }];
      };
    });

  # Registers a systemd oneshot per microvm that submits the job to the cluster; hosts that run nomad
  # clients import this (see server-cluster.nix).
  config.flake.modules.nixos.nomad-job = { config, ... }: {
    # note: `nomad job run` is a no-op when the job is unchanged
    systemd.services = lib.mapAttrs' (name: vm: lib.nameValuePair "nomad-job-${name}" {
      after = [ "nomad.service" ];
      requires = [ "nomad.service" ];
      wantedBy = [ "multi-user.target" ];
      path = [ config.services.nomad.package ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        Restart = "on-failure"; # retry until the cluster has elected a leader
        RestartSec = 10;
      };
      script = "nomad job run -detach -json ${
        inputs.self.lib.mkNomadJob {
          inherit name;
          vmSystem = vm;
          vfs = microvms.${name}.vfs;
          constraints = microvms.${name}.nomad.constraints;
        }
      }";
    }) vmSystems;
  };
}
