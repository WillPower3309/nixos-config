{ inputs, lib, ... }:

let
  clusterInterface = "eth0";
  lanInterface = "sfp0";
  lanVlan = 10; # TODO: understand why we have to tag when the trunk port default is 10
  lanVlanInterface = "${lanInterface}.${toString lanVlan}";
  numVfs = 64;

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
  initNode = "node0";

# TODO: NTP?
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
      cluster # SR-IOV pod networking and the pods (sriov.nix, home-assistant.nix, unifi-os.nix)
    ];

    # authorize connected USB4 devices so their network interfaces auto appear
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="thunderbolt", ATTR{authorized}=="0", ATTR{authorized}="1"
    '';

    networking = {
      inherit hostName;
      usePredictableInterfaceNames = false; # TODO: needed given the systemd.network.links?
      useDHCP = false;
      firewall = {
        # pods on flannel (coredns, metrics-server) reach the API server and kubelet through these
        trustedInterfaces = [ "cni0" "flannel.1" ];
        interfaces = {
          "${lanVlanInterface}".allowedTCPPorts = [ 6443 ]; # kubectl from the LAN
          "${clusterInterface}" = {
            allowedTCPPorts = [
              6443 # API server
              2379 2380 # etcd
              10250 # kubelet
            ];
            allowedUDPPorts = [ 8472 ]; # flannel vxlan
          };
        };
      };
    };

    # TODO: seaweedfs USB4 mesh network: https://fangpenlin.com/posts/2024/01/14/high-speed-usb4-mesh-network/
    # TODO: fallback routing for mesh network: https://pve.proxmox.com/wiki/Full_Mesh_Network_for_Ceph_Server#Routed_Setup_(with_Fallback)
    systemd.network = {
      enable = true;
      links = {
        "10-${lanInterface}" = {
          matchConfig.PermanentMACAddress = node.lanMacAddress;
          linkConfig = {
            Name = lanInterface;
            SR-IOVVirtualFunctions = numVfs;
          };
        };
        "10-${clusterInterface}" = {
          matchConfig.PermanentMACAddress = node.clusterMacAddress;
          linkConfig.Name = clusterInterface;
        };
      };
      netdevs."20-${lanVlanInterface}" = {
        netdevConfig = {
          Kind = "vlan";
          Name = lanVlanInterface;
        };
        vlanConfig.Id = lanVlan;
      };
      networks = {
        "10-${lanInterface}" = {
          matchConfig.Name = lanInterface;
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
      kernelModules = [ "thunderbolt_net" ];

      # the LUKS2 volume is unlocked by the TPM (enrolled against PCR 7, the Secure Boot state)
      initrd = {
        luks.devices.crypted.crypttabExtraOpts = [ "tpm2-device=auto" ];
        systemd = {
          enable = true;
          tpm2.enable = true;
        };
      };
    };

    hardware.enableAllFirmware = true;

    # TODO: joining needs a shared token (agenix tokenFile)
    services.k3s = {
      enable = true;
      role = "server";
      clusterInit = hostName == initNode;
      serverAddr = lib.mkIf (hostName != initNode) "https://${nodes.${initNode}.clusterIpAddress}:6443";
      nodeIP = node.clusterIpAddress;
      disable = [ "traefik" "servicelb" ]; # no ingress or load balancer yet
      extraFlags = [
        "--snapshotter nix"
        "--flannel-iface=${clusterInterface}"
        "--tls-san=${node.lanIpAddress}" # kubectl from the LAN
      ];
      gracefulNodeShutdown.enable = true;
    };

    # the nix snapshotter shells out to nix-store; keep it on the k3s service PATH
    systemd.services.k3s.path = [ pkgs.nix ];

    environment = {
      etc."ssh/ssh_host_ed25519_key.pub".source = ./ssh_host_ed25519_key.pub;
      persistence.${config.constants.persistentDir}.directories = [
        "/etc/rancher" # includes the node password the cluster knows this node by
        "/var/lib/rancher" # etcd, containerd images and snapshots
        "/var/lib/kubelet"
        "/var/lib/cni"
        "/var/lib/workloads" # pod state (hostPath volumes)
      ];
    };
  }) nodes;
}
