{ inputs, ... }:

let
  authorizedKey = builtins.readFile ../../features/ssh-client/id_ed25519.pub;
  rj45Interface = "eth0";
  sfpInterface = "sfp0";
  sfpMacAddress = "38:05:25:31:58:aa";
  hostName = "proxmox";
  ipAddress = "10.1.10.3";
  numSfpVfs = 16;
  sfpVfDeviceId = "8086:154c";

  # The i40e PF at 0000:03:00.0 exposes VFs as 0000:03:02.0 through
  # 0000:03:(02 + ceil(N/8) - 1).(N % 8).
  sfpVfPcis = builtins.genList (idx:
    let
      dev = 2 + builtins.div idx 8;
      func = builtins.sub idx (8 * builtins.div idx 8);
      bdf = "0000:03:0${toString dev}.${toString func}";
    in
      { inherit idx bdf; deviceUnit = "sys-devices-pci0000:00-0000:00:06.2-${bdf}.device"; }
  ) numSfpVfs;

# TODO: router VF will need `trust on`
# TODO: NTP (https://pve.proxmox.com/wiki/Time_Synchronization)
in {
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "proxmox";

  flake.networks."10".reservations = [{
    ip-address = ipAddress;
    hostname = hostName;
    hw-address = "${sfpMacAddress}";
  }];

  flake.modules.nixos.proxmox = { config, pkgs, lib, ... }: {
    imports = with inputs.self.modules.nixos; [
      common
      ssh-server
    ] ++ [
      inputs.proxmox-nixos.nixosModules.proxmox-ve
      inputs.agenix.nixosModules.age
    ];

    nixpkgs.overlays = [ inputs.proxmox-nixos.overlays.x86_64-linux ];

    # 38:05:25:31:58:aa -> SR-IOV PF (host + VMs)
    # 38:05:25:31:58:ab -> (BLACKLISTED) unused SFP port
    # 38:05:25:31:58:ac -> corosync
    # 38:05:25:31:58:ad -> (BLACKLISTED) intel AMT ethernet port
    # auto-authorize connected USB4 devices so network interfaces appear without manual intervention
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="${sfpMacAddress}", NAME="${sfpInterface}", RUN+="${pkgs.bash}/bin/sh -c '${pkgs.coreutils}/bin/echo ${toString numSfpVfs} > /sys/class/net/${sfpInterface}/device/sriov_numvfs'"
      ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="38:05:25:31:58:ac", NAME="${rj45Interface}"
      ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="38:05:25:31:58:ab", RUN+="${pkgs.bash}/bin/sh -c 'echo 1 > /sys/class/net/%k/device/remove'"
      ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="38:05:25:31:58:ad", RUN+="${pkgs.bash}/bin/sh -c 'echo 1 > /sys/class/net/%k/device/remove'"
      ACTION=="add", SUBSYSTEM=="thunderbolt", ATTR{authorized}=="0", ATTR{authorized}="1"
    '';

    networking = {
      inherit hostName;
      usePredictableInterfaceNames = false;
      useDHCP = false;
    };

    systemd.services."pve-guests" = {
      after = [ "pvedaemon.service" ];
      unitConfig.JobTimeoutSec = 300;

      # TODO: add mappings for the other nodes in the cluster
      # TODO: configuration for subsystem-id not correct != 8086:0000
      # TODO: configuration for iommugroup not correct != 16-34
      preStart = let
        waitAndMap = p: ''
          if [ ! -e /sys/bus/pci/devices/${p.bdf} ]; then
            for i in $(seq 1 30); do
              if [ -e /sys/bus/pci/devices/${p.bdf} ]; then
                break
              fi
              sleep 1
            done
            if [ ! -e /sys/bus/pci/devices/${p.bdf} ]; then
              echo "VF ${p.bdf} never appeared" >&2
              exit 1
            fi
          fi
      ${pkgs.proxmox-ve}/bin/pvesh create /cluster/mapping/pci \
          --id sfp-vf-${toString p.idx} \
          --map "node=${hostName},path=${p.bdf},id=${sfpVfDeviceId}" \
          || ${pkgs.proxmox-ve}/bin/pvesh set /cluster/mapping/pci/sfp-vf-${toString p.idx} \
              --map "node=${hostName},path=${p.bdf},id=${sfpVfDeviceId}"
        '';
      in lib.concatStringsSep "\n" (builtins.map waitAndMap sfpVfPcis);
    };

    # TODO: USB4 mesh network: https://fangpenlin.com/posts/2024/01/14/high-speed-usb4-mesh-network/
    # TODO: fallback routing for mesh network: https://pve.proxmox.com/wiki/Full_Mesh_Network_for_Ceph_Server#Routed_Setup_(with_Fallback)
    systemd.network = {
      enable = true;
      networks = {
        "10-${sfpInterface}" = {
          matchConfig.MACAddress = sfpMacAddress; # match macAddress to ensure it works in initrd conf too
          DHCP = "no";
          address = [ "${ipAddress}/24" ];
          gateway = [ "10.1.10.1" ];
        };
        "20-${rj45Interface}" = {
          matchConfig.Name = rj45Interface;
          DHCP = "no";
          address = [ "10.1.90.1/24" ];
        };
      };
    };

    boot = {
      kernelModules = [ "vfio" "vfio_iommu_type1" "vfio_pci" "thunderbolt_net" ];
      kernelParams = [ "intel_iommu=on" "iommu=pt" ];

      initrd = {
        kernelModules = [ "i40e" ];
        systemd = {
          enable = true;
          network = {
            enable = true;
            networks."10-${sfpInterface}" = config.systemd.network.networks."10-${sfpInterface}";
          };
          users.root.shell = "${pkgs.util-linux}/bin/nologin"; # block interactive shell access
        };
        network = {
          enable = true;
          ssh = {
            enable = true;
            port = config.constants.sshBootPort;
            authorizedKeys = lib.map (key:
              "command=\"/bin/systemd-tty-ask-password-agent\",restrict,pty ${key}"
            ) config.users.users.root.openssh.authorizedKeys.keys;
            hostKeys = [ "${config.constants.persistentDir}/etc/ssh/ssh_host_ed25519_key" ];
          };
        };
      };
    };

    hardware.enableAllFirmware = true;

    age.secrets.proxmoxRsaPrivateKey.file = ./proxmoxRsaPrivateKey.age;

    environment = {
      persistence."${config.constants.persistentDir}".directories = [
        "/var/lib/pve-cluster"
        "/etc/corosync"
        "/var/lib/vz" # VM disk image storage
      ];

      etc = {
        "ssh/ssh_host_ed25519_key.pub".source = ./ssh_host_ed25519_key.pub;

        # used by pveproxy
        "ssh/ssh_host_rsa_key.pub".source = ./ssh_host_rsa_key.pub;
        "ssh/ssh_host_rsa_key".source = config.age.secrets.proxmoxRsaPrivateKey.path;
      };
    };

    services.proxmox-ve = {
      inherit ipAddress;
      enable = true;
      openFirewall = true;
    };
  };
}
