{ config, pkgs, lib, inputs, ... }:

let
  authorizedKey = (builtins.readFile ../../home/id_ed25519.pub);
  hostKeyPath = /etc/ssh/ssh_host_ed25519_key;
  ipAddress = "10.1.10.3";
  rj45Interface0 = "eth0";
  rj45Interface1 = "eth1";
  sfpInterface0 = "sfp0";
  sfpInterface1 = "sfp1";

  # set a number of network interface VFs equal to the number of VMs + 2
  # (one for router WAN and one for the PVE host itself)
  numNetVfs = lib.pipe ./vms [
    builtins.readDir
    builtins.attrNames
    builtins.length
    (count: count + 2)
  ];
  numGpuVfs = 2; # only need for plex and immich vms

in
{
  imports = [
    inputs.agenix.nixosModules.default
    inputs.proxmox-nixos.nixosModules.proxmox-ve
    ./disks.nix
  ];

  nixpkgs.overlays = [ inputs.proxmox-nixos.overlays.x86_64-linux ];

  # 1. Match by MAC, assign stable kernel-style name:
  #   38:05:28:31:AD / rj45Interface0: corosync
  #   38:05:28:31:AD / rj45Interface1: intel AMT ethernet port (as it uses the I226-LM controller)
  #   38:05:28:31:AD / sfpInterface0: SR-IOV - used for host and VMs
  #   38:05:28:31:AD / sfpInterface1: unused
  # 2. Trigger SR-IOV creation once the SFP driver registers sfpInterface0
  # 3. Disable "spoof checking" and enables "trust" on VF 0 so the host can handle advanced network stacks
  # 4. Enforce the embedded hardware switch to allow local VF-to-VF looping
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="38:05:25:31:58:ac", NAME="${rj45Interface0}"
    ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="38:05:25:31:58:ad", NAME="${rj45Interface1}"

    ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="38:05:25:31:58:aa", NAME="${sfpInterface0}", RUN+="${pkgs.bash}/bin/bash -c '\
      echo ${numNetVfs} > /sys/class/net/%k/device/sriov_numvfs && \
      ${pkgs.iproute2}/bin/ip link set dev %k vf 0 trust on spoofchk off && \
      ${pkgs.udev}/bin/udevadm trigger --attr-match=subsystem=net'"
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="${sfpInterface0}v0", RUN+="${pkgs.iproute2}/bin/bridge link set dev %k hairpin on"

    ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="38:05:25:31:58:ab", NAME="${sfpInterface1}"
  '';

  # use the first virtual function as the host's interface
  networking = let hostInterface = "${sfpInterface0}v0"; in {
    hostName = "proxmox";
    usePredictableInterfaceNames = false; # set interface names via services.udev.extraRules above
    useDHCP = false;
    wireless.enable = false;
    networkmanager.enable = lib.mkForce false;
    useNetworkd = true;

    # Bind the Host Static IP directly to the first Virtual Function (VF 0)
    interfaces."${hostInterface}" = {
      # TODO: use "stable" instead?
      macAddress = "38:05:25:31:58:af"; # VFs get a randomized mac on boot: set a static mac to be nice to ARP caches
      ipv4.addresses = [{
        address = ipAddress;
        prefixLength = 24;
      }];
    };

    # Route host traffic strictly through the dedicated VF
    defaultGateway = {
      address = "10.1.10.1"; # TODO: define statically somewhere as this is also needed for router
      interface = "${hostInterface}";
    };

    # TODO: ceph USB4 mesh network: https://fangpenlin.com/posts/2024/01/14/high-speed-usb4-mesh-network/
    # TODO: fallback routing for the ceph mesh network: https://pve.proxmox.com/wiki/Full_Mesh_Network_for_Ceph_Server#Routed_Setup_(with_Fallback)
  };

  age.secrets.hashedRootPassword.file = ../../secrets/hashedRootPassword.age;

  users = {
    users.root = {
      hashedPasswordFile = config.age.secrets.hashedRootPassword.path;
      openssh.authorizedKeys.keys = [ authorizedKey ];
    };
    mutableUsers = false;
  };

  boot = {
    # needed for SR-IOV
    kernelModules = [ "vfio" "vfio_iommu_type1" "vfio_pci" ];
    kernelParams = [ "intel_iommu=on" "iommu=pt" "i915.enable_guc=3" "i915.max_vfs=${toString numGpuVfs}" ];
    # TODO sriov gpu: https://www.michaelstinkerings.org/gpu-virtualization-with-intel-12th-gen-igpu-uhd-730/
    # kernel.sysfs.devices."pci0000:00"."0000:00:02.0".sriov_numvfs = numGpuVfs; # set the number of vfs for the igpu

    loader.systemd-boot = {
      enable = true;
      editor = false; # true allows gaining root access by passing init=/bin/sh as a kernel parameter
    };

    initrd = {
      # TODO: does this still work for SFP port
      kernelModules = [ "igc" ]; # intel ethernet controller

      network = {
        enable = true;
        ssh = {
          enable = true;
          port = 2222;
          authorizedKeys = lib.map (key: "command=\"/bin/systemd-tty-ask-password-agent\",restrict,pty ${key}") config.users.users.root.openssh.authorizedKeys.keys;
          hostKeys = [ (/persist + hostKeyPath) ];
        };
      };
    };
  };

  hardware.enableAllFirmware = true;

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

  age.secrets.proxmoxRsaPrivateKey.file = ../../secrets/proxmoxRsaPrivateKey.age;

  environment = {
    persistence."/nix/persist".directories = [ "/var/lib/pve-cluster" ];

    etc = {
      "ssh/ssh_host_ed25519_key.pub".source = ./ssh_host_ed25519_key.pub;
      # pveproxy needs rsa keys to work
      "ssh/ssh_host_rsa_key.pub".source = ./ssh_host_rsa_key.pub;
      "ssh/ssh_host_rsa_key".source = config.age.secrets.proxmoxRsaPrivateKey.path;
    };
  };

  services.proxmox-ve = {
    enable = true;
    openFirewall = true;
    ipAddress = ipAddress;
  };
}

