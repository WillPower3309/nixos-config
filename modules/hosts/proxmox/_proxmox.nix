{ inputs, ... }:

let
  authorizedKey = builtins.readFile ../../../modules/home/id_ed25519.pub;
  ipAddress = "10.1.10.3";
  rj45Interface0 = "eth0";
  rj45Interface1 = "eth1";
  sfpInterface0 = "sfp0";
  sfpInterface1 = "sfp1";

  numNetVfs = 32; # TODO: better value, remove var (only used once)?
  numGpuVfs = 2;

in
{
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "proxmox";

  flake.modules.nixos.proxmox = { config, pkgs, lib, ... }: {
    imports = with inputs.self.modules.nixos; [
      common
      ssh-server
    ] ++ [
      inputs.proxmox-nixos.nixosModules.proxmox-ve
      inputs.agenix.nixosModules.age
    ];

    nixpkgs.overlays = [ inputs.proxmox-nixos.overlays.x86_64-linux ];

    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="38:05:25:31:58:ac", NAME="${rj45Interface0}"
      ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="38:05:25:31:58:ad", NAME="${rj45Interface1}"

      ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="38:05:25:31:58:aa", NAME="${sfpInterface0}", RUN+="${pkgs.bash}/bin/bash -c '\
        echo ${toString numNetVfs} > /sys/class/net/%k/device/sriov_numvfs && \
        ${pkgs.iproute2}/bin/ip link set dev %k vf 0 trust on spoofchk off && \
        ${pkgs.udev}/bin/udevadm trigger --attr-match=subsystem=net'"
      ACTION=="add", SUBSYSTEM=="net", KERNEL=="${sfpInterface0}v0", RUN+="${pkgs.iproute2}/bin/bridge link set dev %k hairpin on"

      ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="38:05:25:31:58:ab", NAME="${sfpInterface1}"
    '';

    networking = let hostInterface = "${sfpInterface0}v0"; in {
      hostName = "proxmox";
      usePredictableInterfaceNames = false;
      useDHCP = false;

      interfaces."${hostInterface}" = {
        macAddress = "38:05:25:31:58:af";
        ipv4.addresses = [{
          address = ipAddress;
          prefixLength = 24;
        }];
      };

      defaultGateway = {
        address = "10.1.10.1";
        interface = "${hostInterface}";
      };
    };

    age.secrets.hashedRootPassword.file = "${inputs.secrets}/hashedRootPassword.age";

    users = {
      users.root = {
        hashedPasswordFile = config.age.secrets.hashedRootPassword.path;
        openssh.authorizedKeys.keys = [ authorizedKey ];
      };
      mutableUsers = false;
    };

    boot = {
      kernelModules = [ "vfio" "vfio_iommu_type1" "vfio_pci" ];
      kernelParams = [ "intel_iommu=on" "iommu=pt" "i915.enable_guc=3" "i915.max_vfs=${toString numGpuVfs}" ];

      loader.systemd-boot = {
        enable = true;
        editor = false;
      };

      initrd = {
        kernelModules = [ "igc" ];
        network = {
          enable = true;
          ssh = {
            enable = true;
            port = 2222;
            authorizedKeys = lib.map (key: "command=\"/bin/systemd-tty-ask-password-agent\",restrict,pty ${key}") config.users.users.root.openssh.authorizedKeys.keys;
            hostKeys = [ (/persist/etc/ssh/ssh_host_ed25519_key) ];
          };
        };
      };
    };

    hardware.enableAllFirmware = true;

    age.secrets.proxmoxRsaPrivateKey.file = "${inputs.secrets}/proxmoxRsaPrivateKey.age";

    environment = {
      persistence."/nix/persist".directories = [ "/var/lib/pve-cluster" ];

      etc = {
        "ssh/ssh_host_ed25519_key.pub".source = ./ssh_host_ed25519_key.pub;
        "ssh/ssh_host_rsa_key.pub".source = ./ssh_host_rsa_key.pub;
        "ssh/ssh_host_rsa_key".source = config.age.secrets.proxmoxRsaPrivateKey.path;
      };
    };

    services.proxmox-ve = {
      enable = true;
      openFirewall = true;
      ipAddress = ipAddress;
    };
  };
}
