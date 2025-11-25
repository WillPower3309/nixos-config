{ config, pkgs, lib, impermanence, agenix, proxmox-nixos, ... }:

let
  authorizedKey = (builtins.readFile ../../home/id_ed25519.pub);
  hostKeyPath = /etc/ssh/ssh_host_ed25519_key;
  ipAddress = "10.27.27.10";
  rj45Interface0 = "eth0";
  rj45Interface1 = "eth1";
  sfpInterface0 = "eth2";
  sfpInterface1 = "eth3";
  bridgeInterface = "vmbr0";
  bondInterface = "bond0";

  wanVlanId = 100;
  lanVlanId = 101;

in
{
  imports = [
    agenix.nixosModules.default
    impermanence.nixosModules.impermanence
    proxmox-nixos.nixosModules.proxmox-ve
    ./disks.nix
    ../../modules/nix.nix
  ];

  nixpkgs.overlays = [
    proxmox-nixos.overlays.x86_64-linux
  ];

  services = {
    # 38:05:28:31:AD / rj45Interface1 is the intel AMT ethernet port (uses the I226-LM controller)
    udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="38:05:25:31:58:ac", NAME="${rj45Interface0}"
      ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="38:05:25:31:58:ad", NAME="${rj45Interface1}"
      ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="38:05:25:31:58:aa", NAME="${sfpInterface0}"
      ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="38:05:25:31:58:ab", NAME="${sfpInterface1}"
    '';
  };

  networking = {
    hostName = "proxmox";
    usePredictableInterfaceNames = false; # set interface names via services.udev.extraRules above
    useDHCP = false;
    wireless.enable = false;
    networkmanager.enable = lib.mkForce false;
    useNetworkd = true;

    defaultGateway = {
      address = "10.27.27.1";
      interface = rj45Interface0;
    };

    bonds."${bondInterface}" = {
      interfaces = [ sfpInterface0 sfpInterface1 ];
      driverOptions = {
        miimon = "100"; # monitor mii link every 100s
        mode = "802.3ad"; # dynamic LACP
        xmit_hash_policy = "layer2+3";
      };
    };

    bridges."${bridgeInterface}".interfaces = [ rj45Interface0 ];

    vlans = {
      "vlan${toString wanVlanId}" = {
        id = wanVlanId;
        interface = bridgeInterface;
      };
      "vlan${toString lanVlanId}" = {
        id = lanVlanId;
        interface = bridgeInterface;
      };
    };

    interfaces = {
      "${bridgeInterface}".ipv4.addresses = [{
        address = ipAddress;
        prefixLength = 24;
      }];

      "vlan${toString wanVlanId}".ipv4.addresses = [{
        address = "10.1.1.1";
        prefixLength = 24;
      }];

      "vlan${toString lanVlanId}".ipv4.addresses = [{
        address = "10.1.1.2";
        prefixLength = 24;
      }];
    };

    # TODO: ceph USB4 mesh network: https://fangpenlin.com/posts/2024/01/14/high-speed-usb4-mesh-network/
    # TODO: fallback routing for the ceph mesh network: https://pve.proxmox.com/wiki/Full_Mesh_Network_for_Ceph_Server#Routed_Setup_(with_Fallback)
  };

  boot.loader.systemd-boot = {
    enable = true;
    editor = false; # true allows gaining root access by passing init=/bin/sh as a kernel parameter
  };

  hardware.enableAllFirmware = true;

  age.secrets.hashedRootPassword.file = ../../secrets/hashedRootPassword.age;

  users = {
    users.root = {
      hashedPasswordFile = config.age.secrets.hashedRootPassword.path;
      openssh.authorizedKeys.keys = [ authorizedKey ];
    };
    mutableUsers = false;
  };

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
    hostKeys = [{
      path = "/nix/persist/${(toString hostKeyPath)}";
      type = "ed25519";
    }];
  };

  # Set your time zone.
  time.timeZone = "America/Toronto";

  environment = {
    persistence."/nix/persist" = {
      hideMounts = true;
      directories = [
        "/var/log"
        "/var/lib/nixos"
        "/var/lib/pve-cluster"
      ];
      files = [ (toString hostKeyPath) ];
    };

    etc."ssh/ssh_host_ed25519_key.pub".source = ./ssh_host_ed25519_key.pub;
  };

  services.proxmox-ve = {
    enable = true;
    openFirewall = true;
    ipAddress = ipAddress;
    bridges = [ bridgeInterface ];
  };

  system.stateVersion = config.system.nixos.release;
}

