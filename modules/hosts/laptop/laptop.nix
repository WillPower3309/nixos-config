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
    ];

    boot = {
      initrd = {
        availableKernelModules = [ "nvme" "xhci_pci" "thunderbolt" "usb_storage" "usbhid" "sd_mod" ];
        kernelModules = [ "dm-snapshot" "amdgpu" ];
      };
      kernelModules = [ "kvm-amd" ];
      kernelParams = [ "amdgpu.dcdebugmask=0x10" ]; # PSR hang workaround for Framework 16
      extraModulePackages = [ config.boot.kernelPackages.framework-laptop-kmod ];
    };

    hardware = {
      enableAllFirmware = true;
      cpu.amd.updateMicrocode = config.hardware.enableRedistributableFirmware;
      amdgpu.initrd.enable = true;
      sensor.iio.enable = true;
      keyboard.qmk.enable = true;
    };

    services = {
      fwupd.enable = true;
      fstrim.enable = true;
      fprintd.enable = true;
    };

    services.udev.extraRules = ''
      # Allow access to the keyboard modules for programming
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="32ac", ATTRS{idProduct}=="0012", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
    '';

    environment.systemPackages = with pkgs; [
      brightnessctl
      framework-tool
    ];

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

    environment.etc = {
      "ssh/ssh_host_ed25519_key.pub".source = ./ssh_host_ed25519_key.pub;
      "libinput/local-overrides.quirks".text = ''
        [Framework Laptop 16 Keyboard Module]
        MatchName=Framework Laptop 16 Keyboard Module*
        MatchUdevType=keyboard
        MatchDMIModalias=dmi:*svnFramework:pnLaptop16*
        AttrKeyboardIntegration=internal
      '';
    };
  };
}

