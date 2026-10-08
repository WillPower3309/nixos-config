{ config, inputs, lib, ... }:

let
  nodes = {
    node0 = { interface = "eth0"; address = "10.1.90.1"; };
  };
  servers = lib.mapAttrsToList (_: node: node.address) nodes;
  system = "x86_64-linux";
  # every microvm from modules/vms/ is scheduled on the cluster (see modules/microvms.nix)
  microvms = config.flake.microvms;

in {
  # inspired by https://github.com/astro/skyflake/blob/main/nixos-modules/nomad.nix
  flake.modules.nixos.nomad = { config, lib, pkgs, ... }: let
    cfg = config.nomad;
    vmSystems = lib.mapAttrs (name: _: (inputs.self.lib.mkNixos system name).${name}) microvms;
    node = nodes.${config.networking.hostName} or (throw "${config.networking.hostName} is not a nomad node (see modules/features/nomad.nix)");
    seconds = s: s * 1000000000; # nomad API durations are in nanoseconds

    # Adapted from https://github.com/astro/skyflake/blob/main/vm/nomad-job.nix
    mkMicrovmJob = name: vmSystem: let
      inherit (microvms.${name}) nomad vfs;
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
          }) nomad.constraints;
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
  in {
    options.nomad.vfs = lib.mkOption {
      description = "SR-IOV virtual functions on this node for the microvms scheduled here, which claim free ones at startup as their NICs (see flake.microvms.<name>.vfs)";
      type = lib.types.listOf (lib.types.submodule {
        options = {
          pciAddress = lib.mkOption { type = lib.types.str; example = "0000:03:02.0"; };
          deviceUnit = lib.mkOption {
            type = lib.types.str;
            description = "systemd device unit of the VF, which nomad waits for";
            example = "sys-devices-pci0000:00-0000:00:06.2-0000:03:02.0.device";
          };
        };
      });
    };

    config = {
      # this node's VFs, one PCI address per line, which the hypervisor scripts claim from
      environment.etc.microvm-vfs.text = lib.concatMapStrings (vf: "${vf.pciAddress}\n") cfg.vfs;

      services.nomad = {
        enable = true;
        dropPrivileges = false; # raw_exec tasks run as the microvm user
        enableDocker = false;
        settings = {
          # TODO: enable ACLs; without them anyone reaching the HTTP API can run raw_exec jobs as root
          bind_addr = "0.0.0.0";
          addresses = lib.genAttrs [ "rpc" "serf" ] (_: node.address);
          advertise = lib.genAttrs [ "http" "rpc" "serf" ] (_: node.address);
          server = {
            enabled = true;
            bootstrap_expect = (builtins.length servers + 2) / 2;
            server_join.retry_join = servers;
          };
          client = {
            enabled = true;
            network_interface = node.interface;
            server_join.retry_join = servers;
          };
          plugin.raw_exec.config.enabled = true;
        };
      };

      # bind the VFs to vfio-pci as they appear (requires sriov_drivers_autoprobe=0 on the PF so the host
      # driver doesn't claim them first), and tag them so their systemd device units appear once bound.
      services.udev.extraRules = lib.concatMapStrings (vf: ''
        ACTION=="add", SUBSYSTEM=="pci", KERNEL=="${vf.pciAddress}", ATTR{driver_override}="vfio-pci", RUN+="${pkgs.bash}/bin/sh -c '${pkgs.kmod}/bin/modprobe vfio-pci && echo %k > /sys/bus/pci/drivers_probe'"
        SUBSYSTEM=="pci", KERNEL=="${vf.pciAddress}", DRIVER=="vfio-pci", TAG+="systemd"
      '') cfg.vfs + ''
        SUBSYSTEM=="vfio", GROUP="kvm", MODE="0660"
      '';

      systemd.services = lib.mkMerge [{
        nomad = {
          # don't start (and restore microvm allocations) until the VFs are bound to vfio-pci
          requires = map (vf: vf.deviceUnit) cfg.vfs;
          after = map (vf: vf.deviceUnit) cfg.vfs;
          serviceConfig.LimitMEMLOCK = "infinity"; # vfio pins all guest memory; inherited by raw_exec tasks
        };
      } (
      # note: `nomad job run` is a no-op when the job is unchanged
      lib.mapAttrs' (name: vm: lib.nameValuePair "nomad-job-${name}" {
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
        script = "nomad job run -detach -json ${mkMicrovmJob name vm}";
      }) vmSystems)];

      users.users.microvm = {
        isSystemUser = true;
        group = "kvm";
      };

      systemd.tmpfiles.rules = [ "d /var/lib/microvms 0750 microvm kvm - -" ];

      environment.persistence.${config.constants.persistentDir}.directories = [
        "/var/lib/nomad"
        { directory = "/var/lib/microvms"; user = "microvm"; group = "kvm"; mode = "0750"; }
      ];

      networking.firewall = {
        interfaces.${node.interface} = {
          allowedTCPPorts = [ 4647 4648 ];
          allowedUDPPorts = [ 4648 ];
        };
      };
    };
  };
}
