{ config, inputs, lib, ... }:

let
  pkgs = inputs.nixpkgs.legacyPackages."x86_64-linux";
  # the same nomad the nodes run (services.nomad.package defaults to it), which is unfree
  nomad = (import inputs.nixpkgs {
    system = "x86_64-linux";
    config.allowUnfreePredicate = pkg: lib.getName pkg == "nomad";
  }).nomad;

  # Builds the nomad job spec (and the hypervisor script) that runs the microvm
  # Inspired by https://github.com/astro/skyflake/blob/main/nixos-modules/nomad-job.nix
  mkNomadJob = name: microvm:
    let
      seconds = s: s * 1000000000; # nomad API durations are in nanoseconds
      vmSystem = (inputs.self.lib.mkNixos "x86_64-linux" name).${name};
      vm = vmSystem.config;
      # The VM's NICs are the VFs claimed below, added to qemu's args at runtime
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

        # A VF is claimed by holding a flock on its lock file, so two VMs starting at once can't both take the same one
        # The fds aren't close-on-exec, so qemu inherits them and the claim lasts as long as the VM
        mkdir -p /run/microvm-vfs
        claim_vf() {
          local mac=$1 vlan=$2 addr pf idx fd
          while read -r addr pf idx; do
            exec {fd}>"/run/microvm-vfs/$addr.lock"
            if flock -n "$fd"; then
              ip link set dev "$pf" vf "$idx" mac "$mac" vlan "$vlan"
              claimed_vfs="$claimed_vfs $addr"
              return
            fi
            exec {fd}>&-
          done </etc/microvm-vfs
          echo "No free VF on this node" >&2
          exit 1 # releases any VFs already claimed; nomad restarts, then reschedules the allocation
        }

        claimed_vfs=
        ${lib.concatMapStrings (vf: ''
          claim_vf ${vf.mac} ${toString (if vf.vlan == null then 0 else vf.vlan)}
        '') microvm.vfs}
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
        Meta.managed-by = "nixos"; # lets nomad-sync find (and remove) jobs dropped from the flake
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
          }) microvm.nomad.constraints;
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

  # Every node keeps all job closures, so whichever one nomad picks already has the VM's store paths
  jobs = pkgs.linkFarm "nomad-jobs"
    (lib.mapAttrs' (name: microvm: lib.nameValuePair "${name}.json" (mkNomadJob name microvm)) config.flake.microvms);

  nomadSync = pkgs.writeShellApplication {
    name = "nomad-sync";
    runtimeInputs = [ nomad pkgs.jq ];
    text = ''
      if [ $# -ne 1 ]; then
        echo "usage: nomad-sync <node host>" >&2
        exit 1
      fi
      export NOMAD_ADDR=http://$1:4646
      shopt -s nullglob

      # `nomad job run` is a no-op for unchanged jobs, so only changed VMs are touched
      for job in ${jobs}/*.json; do
        nomad job run -detach -json "$job"
      done

      nomad operator api '/v1/jobs?meta=true' </dev/null \
        | jq -r '.[] | select(.Meta."managed-by" == "nixos") | .ID' \
        | while read -r id; do
            if [ ! -e "${jobs}/$id.json" ]; then
              echo "Stopping removed job $id" >&2
              nomad job stop -detach -purge -yes "$id" </dev/null
            fi
          done
    '';
  };
in {
  config.flake.modules.nixos.nomad-job.system.extraDependencies = [ jobs ];

  config.flake.apps.x86_64-linux.nomad-sync = {
    type = "app";
    program = "${nomadSync}/bin/nomad-sync";
    meta.description = "Submit the microvm jobs to the nomad cluster and stop removed ones";
  };
}
