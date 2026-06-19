{ inputs, ... }:

let
  authorizedKey = builtins.readFile ../../features/ssh-client/id_ed25519.pub;
  rj45Interface0 = "eth0";
  sfpInterface0 = "sfp0";
  sfpInterface1 = "sfp1";
  sfp0MacAddress = "38:05:25:31:58:aa";
  hostName = "proxmox";
  ipAddress = "10.1.10.3";
  numSfpVfs = 16;

  # The i40e PF at 0000:03:00.0 exposes VFs as 0000:03:02.0 through
  # 0000:03:(02 + ceil(N/8) - 1).(N % 8).
  vfDeviceUnits = builtins.genList (idx:
    let
      dev = 2 + builtins.div idx 8;
      func = builtins.sub idx (8 * builtins.div idx 8); # no mod operator in nix ;-;
    in
      "sys-devices-pci0000:00-0000:00:06.2-0000:03:0${toString dev}.${toString func}.device"
  ) numSfpVfs;

# TODO: router VF will need `trust on`
# TODO: NTP (https://pve.proxmox.com/wiki/Time_Synchronization)
in {
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "proxmox";

  flake.networks.trusted.reservations = [{
    ip-address = ipAddress;
    hostname = hostName;
    hw-address = "${sfp0MacAddress}";
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

    # 1. 38:05:25:31:58:ac / eth0 -> corosync
    # 3. 38:05:25:31:58:ab / sfp1  -> unused
    # 2. 38:05:25:31:58:aa / sfp0  -> SR-IOV PF (host + VMs)
    # 4. 38:05:25:31:58:ad -> (BLACKLISTED) intel AMT ethernet port
    # 5. auto-authorize connected USB4 devices so network interfaces appear without manual intervention
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="38:05:25:31:58:ac", NAME="${rj45Interface0}"
      ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="38:05:25:31:58:ab", NAME="${sfpInterface1}"
      ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="${sfp0MacAddress}", NAME="${sfpInterface0}", RUN+="${pkgs.bash}/bin/sh -c '${pkgs.coreutils}/bin/echo ${toString numSfpVfs} > /sys/class/net/${sfpInterface0}/device/sriov_numvfs'"
      ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="38:05:25:31:58:ad", RUN+="${pkgs.bash}/bin/sh -c 'echo 1 > /sys/class/net/%k/device/remove'"
      ACTION=="add", SUBSYSTEM=="thunderbolt", ATTR{authorized}=="0", ATTR{authorized}="1"
    '';

    networking = {
      inherit hostName;
      usePredictableInterfaceNames = false;
      useDHCP = false;
    };

    # don't start pve-guests until every VF .device unit is active (VF create is async)
    systemd.services."pve-guests" = {
      requires = vfDeviceUnits;
      after = vfDeviceUnits;
    };

    # TODO: fallback routing for mesh network: https://pve.proxmox.com/wiki/Full_Mesh_Network_for_Ceph_Server#Routed_Setup_(with_Fallback)
    # TODO: linstor USB4 mesh network: https://fangpenlin.com/posts/2024/01/14/high-speed-usb4-mesh-network/
    systemd.network = {
      enable = true;
      networks = {
        "10-${sfpInterface0}" = {
          matchConfig.MACAddress = sfp0MacAddress; # match macAddress to ensure it works in initrd conf too
          networkConfig.DHCP = "no";
          addresses = [{ addressConfig.Address = "${ipAddress}/24"; }];
          routes = [{ routeConfig.Gateway = "10.1.10.1"; }];
        };
        "20-${rj45Interface0}" = {
          matchConfig.Name = rj45Interface0;
          networkConfig.DHCP = "no";
          addresses = [{ addressConfig.Address = "10.1.90.1/24"; }];
        };
      };
    };

    boot = {
      kernelModules = [ "vfio" "vfio_iommu_type1" "vfio_pci" "thunderbolt_net" ];
      kernelParams = [ "intel_iommu=on" "iommu=pt" ];

      initrd = {
        kernelModules = [ "i40e" ];
        systemd.network = {
          enable = true;
          networks."10-${sfpInterface0}" = config.systemd.network.networks."10-${sfpInterface0}";
        };
        network = {
          enable = true;
          ssh = {
            enable = true;
            port = 2222;
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

      linstor = {
        enable = true;
        openFirewall = true;
      };
    };
  };
}
