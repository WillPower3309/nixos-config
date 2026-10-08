{ inputs, lib, ... }:

let
  authorizedKey = builtins.readFile ../../features/ssh-client/id_ed25519.pub;
  lanInterface = "sfp0";
  lanVlan = 10;
  lanVlanInterface = "${lanInterface}.${toString lanVlan}";
  clusterInterface = "eth0";
  numSfpVfs = 16;

  # lanMacAddress should point to an SR-IOV capable PF
  nodes = {
    node0 = {
      lanIpAddress = "10.1.10.3";
      lanMacAddress = "38:05:25:31:58:aa";
      clusterIpAddress = "10.1.90.1";
      clusterMacAddress = "38:05:25:31:58:ac";
    };
  };

  # The i40e PF at 0000:03:00.0 exposes VFs as 0000:03:02.0 through
  # 0000:03:(02 + ceil(N/8) - 1).(N % 8).
  sfpVfPcis = builtins.genList (idx:
    let
      dev = 2 + builtins.div idx 8;
      func = builtins.sub idx (8 * builtins.div idx 8);
      bdf = "0000:03:0${toString dev}.${toString func}";
    in
      { pciAddress = bdf; deviceUnit = "sys-devices-pci0000:00-0000:00:06.2-${bdf}.device"; }
  ) numSfpVfs;

# TODO: router VF will need `trust on`
# TODO: NTP (https://pve.proxmox.com/wiki/Time_Synchronization)
in {
  flake.nixosConfigurations = lib.concatMapAttrs (hostName: _:
    inputs.self.lib.mkNixos "x86_64-linux" hostName
  ) nodes;

  flake.networks."10".reservations = lib.mapAttrsToList (hostName: node: {
    hostname = hostName;
    ip-address = node.lanIpAddress;
    hw-address = node.lanMacAddress;
  }) nodes;

  flake.modules.nixos = lib.mapAttrs (hostName: node: { config, pkgs, lib, ... }: {
    imports = with inputs.self.modules.nixos; [
      common
      ssh-server
      nomad
    ];

    # any unused physical ethernet device is removed from the PCI bus
    # auto-authorize connected USB4 devices so network interfaces appear without manual intervention
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="net", ENV{DEVTYPE}!="vlan", ATTR{address}=="${node.lanMacAddress}", NAME="${lanInterface}", RUN+="${pkgs.bash}/bin/sh -c 'echo 0 > /sys/class/net/${lanInterface}/device/sriov_drivers_autoprobe && echo ${toString numSfpVfs} > /sys/class/net/${lanInterface}/device/sriov_numvfs'"
      ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="${node.clusterMacAddress}", NAME="${clusterInterface}"
      ACTION=="add", SUBSYSTEM=="net", KERNEL=="eth*", ATTR{address}!="${node.lanMacAddress}|${node.clusterMacAddress}", TEST=="device/remove", RUN+="${pkgs.bash}/bin/sh -c 'echo 1 > /sys/class/net/%k/device/remove'"
      ACTION=="add", SUBSYSTEM=="thunderbolt", ATTR{authorized}=="0", ATTR{authorized}="1"
    '';

    # VFs are bound to vfio-pci (not the host's iavf driver) and passed through to the microvms
    nomad.vfs = sfpVfPcis;

    # nomad web UI / API from the LAN (cluster ports stay on ${clusterInterface}, see modules/features/nomad.nix)
    networking.firewall.interfaces.${lanVlanInterface}.allowedTCPPorts = [ 4646 ];

    networking = {
      inherit hostName;
      usePredictableInterfaceNames = false;
      useDHCP = false;
    };

    # TODO: seaweedfs USB4 mesh network: https://fangpenlin.com/posts/2024/01/14/high-speed-usb4-mesh-network/
    # TODO: fallback routing for mesh network: https://pve.proxmox.com/wiki/Full_Mesh_Network_for_Ceph_Server#Routed_Setup_(with_Fallback)
    systemd.network = {
      enable = true;
      netdevs."20-${lanVlanInterface}" = {
        netdevConfig = {
          Kind = "vlan";
          Name = lanVlanInterface;
        };
        vlanConfig.Id = lanVlan;
      };
      networks = {
        "10-${lanInterface}" = {
          # match macAddress to ensure it works in initrd conf too; Type excludes the VLAN interface, which shares it
          matchConfig = {
            MACAddress = node.lanMacAddress;
            Type = "ether";
          };
          networkConfig = {
            VLAN = [ lanVlanInterface ];
            LinkLocalAddressing = "no";
          };
          linkConfig.RequiredForOnline = "carrier";
        };
        "15-${lanVlanInterface}" = {
          matchConfig.Name = lanVlanInterface;
          DHCP = "no";
          address = [ "${node.lanIpAddress}/24" ];
          gateway = [ "10.1.10.1" ];
        };
        "20-${clusterInterface}" = {
          matchConfig.Name = clusterInterface;
          DHCP = "no";
          address = [ "${node.clusterIpAddress}/24" ];
        };
      };
    };

    boot = {
      kernelModules = [ "vfio" "vfio_iommu_type1" "vfio_pci" "thunderbolt_net" ];
      kernelParams = [ "intel_iommu=on" "iommu=pt" ];

      initrd = {
        kernelModules = [ "i40e" "8021q" ];
        systemd = {
          enable = true;
          network = {
            enable = true;
            netdevs."20-${lanVlanInterface}" = config.systemd.network.netdevs."20-${lanVlanInterface}";
            networks = {
              "10-${lanInterface}" = config.systemd.network.networks."10-${lanInterface}";
              "15-${lanVlanInterface}" = config.systemd.network.networks."15-${lanVlanInterface}";
            };
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

    environment.etc."ssh/ssh_host_ed25519_key.pub".source = ./ssh_host_ed25519_key.pub;
  }) nodes;
}
