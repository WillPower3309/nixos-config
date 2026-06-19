{ inputs, ... }:

{
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "laptop";

  flake.modules.nixos.laptop = { config, lib, pkgs, ... }: {
    networking.hostName = "laptop";

    imports = with inputs.self.modules.nixos; [
      common
      graphical
      android-dev
      bluetooth
      nebula
      polkit # needed for sway
      power
      syncthing
      wifi
    ] ++ [ inputs.nixos-hardware.nixosModules.framework-16-7040-amd ];

    boot = {
      initrd = {
        availableKernelModules = [ "nvme" "xhci_pci" "thunderbolt" "usb_storage" "usbhid" "sd_mod" ];
        kernelModules = [ "dm-snapshot" "amdgpu" ];
      };
      kernelModules = [ "kvm-amd" ];
    };

    hardware = {
      enableAllFirmware = true;
      cpu.amd.updateMicrocode = config.hardware.enableRedistributableFirmware;
    };

    environment.systemPackages = [ pkgs.brightnessctl ];

    # fingerprint reader
    security.pam.services = {
      polkit-1.fprintAuth = true;
      sudo.fprintAuth = true;
    };

    # set timezone on boot (in case of timezone change)
    # TODO: set up to trigger again in networkmanager / wifi module
    time.timeZone = lib.mkForce null;
    services.tzupdate = {
      enable = true;
      timer.enable = false; # should be a oneshot
    };

    environment.etc."ssh/ssh_host_ed25519_key.pub".source = ./ssh_host_ed25519_key.pub;
  };
}

