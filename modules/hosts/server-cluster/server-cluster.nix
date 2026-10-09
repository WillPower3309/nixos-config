{ config, inputs, lib, ... }:

let
  authorizedKey = builtins.readFile ../../features/ssh-client/id_ed25519.pub;
  lanInterface = "sfp0";
  lanVlan = 10; # TODO: understand why we have to tag when the trunk port default is 10
  lanVlanInterface = "${lanInterface}.${toString lanVlan}";
  clusterInterface = "eth0";
  numVfs = 16;

  # lanMacAddress should point to an SR-IOV capable PF
  # TODO: pass host key too
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
  ) numVfs;

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
      nomad-job
    ];

    # any unused physical ethernet device is removed from the PCI bus
    # auto-authorize connected USB4 devices so network interfaces appear without manual intervention
    # bind the VFs to vfio-pci as they appear (requires sriov_drivers_autoprobe=0 on the PF so the host
    # driver doesn't claim them first), and tag them so their systemd device units appear once bound.
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="net", ENV{DEVTYPE}!="vlan", ATTR{address}=="${node.lanMacAddress}", NAME="${lanInterface}", RUN+="${pkgs.bash}/bin/sh -c 'echo 0 > /sys/class/net/${lanInterface}/device/sriov_drivers_autoprobe && echo ${toString numVfs} > /sys/class/net/${lanInterface}/device/sriov_numvfs'"
      ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="${node.clusterMacAddress}", NAME="${clusterInterface}"
      ACTION=="add", SUBSYSTEM=="net", KERNEL=="eth*", ATTR{address}!="${node.lanMacAddress}|${node.clusterMacAddress}", TEST=="device/remove", RUN+="${pkgs.bash}/bin/sh -c 'echo 1 > /sys/class/net/%k/device/remove'"
      ACTION=="add", SUBSYSTEM=="thunderbolt", ATTR{authorized}=="0", ATTR{authorized}="1"
      SUBSYSTEM=="vfio", GROUP="kvm", MODE="0660"
    '' +
    lib.concatMapStrings (vf: ''
      ACTION=="add", SUBSYSTEM=="pci", KERNEL=="${vf.pciAddress}", ATTR{driver_override}="vfio-pci", RUN+="${pkgs.bash}/bin/sh -c '${pkgs.kmod}/bin/modprobe vfio-pci && echo %k > /sys/bus/pci/drivers_probe'"
      SUBSYSTEM=="pci", KERNEL=="${vf.pciAddress}", DRIVER=="vfio-pci", TAG+="systemd"
    '') sfpVfPcis;

    networking = {
      inherit hostName;
      usePredictableInterfaceNames = false;
      useDHCP = false;
      firewall.interfaces = {
        # nomad web UI / API from the LAN (cluster ports stay on ${clusterInterface})
        "${lanVlanInterface}".allowedTCPPorts = [ 4646 ];
        "${clusterInterface}" = {
          allowedTCPPorts = [ 4647 4648 ];
          allowedUDPPorts = [ 4648 ];
        };
      };
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

    services.nomad = {
      enable = true;
      dropPrivileges = false; # raw_exec tasks run as the microvm user
      enableDocker = false;
      settings = let clusterServers = lib.mapAttrsToList (_: node: node.clusterIpAddress) nodes; in {
        # TODO: enable ACLs; without them anyone reaching the HTTP API can run raw_exec jobs as root
        bind_addr = "0.0.0.0";
        addresses = lib.genAttrs [ "rpc" "serf" ] (_: node.clusterIpAddress);
        advertise = lib.genAttrs [ "http" "rpc" "serf" ] (_: node.clusterIpAddress);
        server = {
          enabled = true;
          bootstrap_expect = (builtins.length clusterServers + 2) / 2;
          server_join.retry_join = clusterServers;
        };
        client = {
          enabled = true;
          network_interface = clusterInterface;
          server_join.retry_join = clusterServers;
        };
        plugin.raw_exec.config.enabled = true;
      };
    };

    systemd.services.nomad = {
      requires = map (vf: vf.deviceUnit) sfpVfPcis;
      after = map (vf: vf.deviceUnit) sfpVfPcis;
      serviceConfig.LimitMEMLOCK = "infinity"; # vfio pins all guest memory; inherited by raw_exec tasks
    };

    users.users.microvm = {
      isSystemUser = true;
      group = "kvm";
    };

    systemd.tmpfiles.rules = [ "d /var/lib/microvms 0750 microvm kvm - -" ];

    environment = {
      etc = {
        # this node's VFs, one PCI address per line, which the hypervisor scripts claim from
        microvm-vfs.text = lib.concatMapStrings (vf: "${vf.pciAddress}\n") sfpVfPcis;
        "ssh/ssh_host_ed25519_key.pub".source = ./ssh_host_ed25519_key.pub;
      };
      persistence.${config.constants.persistentDir}.directories = [
        "/var/lib/nomad"
        { directory = "/var/lib/microvms"; user = "microvm"; group = "kvm"; mode = "0750"; }
      ];
    };
  }) nodes;
}
