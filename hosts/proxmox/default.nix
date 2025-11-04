{ config, pkgs, lib, impermanence, agenix, proxmox-nixos, ... }:

let
  authorizedKey = (builtins.readFile ../../home/id_ed25519.pub);
  hostKeyPath = /etc/ssh/ssh_host_ed25519_key;
  ipAddress = "10.27.27.10";
  rj45InterfaceName0 = "lan0";
  rj45InterfaceName1 = "lan1";
  sfpInterfaceName0 = "lan2";
  sfpInterfaceName1 = "lan3";
  bridgeInterfaceName = "vmbr0";

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
    # 38:05:28:31:AD is the intel AMT ethernet port (uses the I226-LM controller)
    udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="38:05:25:31:58:ac", NAME="${rj45InterfaceName0}"
      ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="38:05:25:31:58:ad", NAME="${rj45InterfaceName1}"
      ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="38:05:25:31:58:aa", NAME="${sfpInterfaceName0}"
      ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="38:05:25:31:58:ab", NAME="${sfpInterfaceName1}"
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
      interface = rj45InterfaceName0;
    };

    bonds.bond0 = {
      interfaces = [ sfpInterfaceName0 sfpInterfaceName1 ];
      driverOptions = {
        miimon = "100"; # monitor mii link every 100s
        mode = "802.3ad"; # dynamic LACP
        xmit_hash_policy = "layer3+4"; # IP and TCP/UDP hash
      };
    };

    bridges.vmbr0.interfaces = [ rj45InterfaceName0 ];

    interfaces = {
      "${rj45InterfaceName0}".ipv4.addresses = [{
        address = ipAddress;
        prefixLength = 24;
      }];

#      "${rj45InterfaceName1}".ipv4.addresses = [{
#        address = "10.27.27.11";
#        prefixLength = 24;
#      }];

      "${bridgeInterfaceName}".useDHCP = lib.mkDefault true;
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
    bridges = [ bridgeInterfaceName ];
  };

  system.stateVersion = config.system.nixos.release;
}

