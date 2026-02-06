{ config, pkgs, lib, inputs, ... }:

let
  authorizedKey = (builtins.readFile ../../home/id_ed25519.pub);
  hostKeyPath = /etc/ssh/ssh_host_ed25519_key;
  ipAddress = "10.27.27.10";
  rj45Interface0 = "eth0";
  rj45Interface1 = "eth1";
  sfpInterface0 = "eth2";
  sfpInterface1 = "eth3";
  bridgeInterface = "vmbr0";

  numGpuVfs = 2; # only need for plex and immich vms

in
{
  imports = [
    inputs.agenix.nixosModules.default
    inputs.impermanence.nixosModules.impermanence
    inputs.proxmox-nixos.nixosModules.proxmox-ve
    ./disks.nix
    ../../modules/nix.nix
  ];

  nixpkgs.overlays = [
    inputs.proxmox-nixos.overlays.x86_64-linux
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

    bridges."${bridgeInterface}".interfaces = [ rj45Interface0 ];

    interfaces = {
      "${bridgeInterface}".ipv4.addresses = [{
        address = ipAddress;
        prefixLength = 24;
      }];
    };

    # TODO: ceph USB4 mesh network: https://fangpenlin.com/posts/2024/01/14/high-speed-usb4-mesh-network/
    # TODO: fallback routing for the ceph mesh network: https://pve.proxmox.com/wiki/Full_Mesh_Network_for_Ceph_Server#Routed_Setup_(with_Fallback)
  };

  # TODO sriov gpu: https://www.michaelstinkerings.org/gpu-virtualization-with-intel-12th-gen-igpu-uhd-730/
  boot = {
    kernelModules = [ "vfio" "vfio_iommu_type1" "vfio_pci" ]; # needed for sriov
    kernelParams = [ "intel_iommu=on" "iommu=pt" "i915.enable_guc=3" "i915.max_vfs=${toString numGpuVfs}" ]; # needed for sriov
    kernel.sysfs = {
      #devices."pci0000:00"."0000:00:02.0".sriov_numvfs = numGpuVfs; # set the number of vfs for the igpu
      # TODO: doesn't work with udev.extrarules
      # TODO: set by mathing the number of files in vms folder
      class.net.${sfpInterface0}.device.sriov_numvfs = 7; # set the number of vfs for the nic
    };
    loader.systemd-boot = {
      enable = true;
      editor = false; # true allows gaining root access by passing init=/bin/sh as a kernel parameter
    };
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

    etc = {
      "ssh/ssh_host_ed25519_key.pub".source = ./ssh_host_ed25519_key.pub;
      # pveproxy needs rsa keys to work
      "ssh/ssh_host_rsa_key.pub".source = ./ssh_host_rsa_key.pub;
      "ssh/ssh_host_rsa_key".source = config.age.secrets.proxmoxRsaPrivateKey.path;
    };
  };
  age.secrets.proxmoxRsaPrivateKey.file = ../../secrets/proxmoxRsaPrivateKey.age;

  services.proxmox-ve = {
    enable = true;
    openFirewall = true;
    ipAddress = ipAddress;
    bridges = [ bridgeInterface ];
  };

  system.stateVersion = config.system.nixos.release;
}

