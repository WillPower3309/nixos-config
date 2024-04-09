{ pkgs, nixos-hardware, ... }:

{
  imports = [
    nixos-hardware.nixosModules.raspberry-pi-4
    ./hardware-configuration.nix
    ../../modules/sound.nix
  ];

  hardware = {
    raspberry-pi."4" = {
      apply-overlays-dtmerge.enable = true;
      fkms-3d.enable = true;
      audio.enable = true;
    };
    deviceTree = {
      enable = true;
      filter = "*rpi-4-*.dtb";
    };
  };

  # TODO: HDMI CEC https://wiki.nixos.org/wiki/NixOS_on_ARM/Raspberry_Pi_4#HDMI-CEC

  console.enable = false;

  environment.systemPackages = with pkgs; [
    libraspberrypi
    raspberrypi-eeprom
  ];

  boot.loader = {
    generic-extlinux-compatible.enable = true;
    grub.enable = false;
  };

  networking = {
    hostName = "media-center";
    wireless.enable = false;
  };

  # Set your time zone.
  time.timeZone = "America/Toronto";

  users.users.viewer = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  };

  services.xserver.desktopManager.plasma5.bigscreen.enable = true;
  services.xserver.displayManager.sddm.enable = true;

  system.stateVersion = "24.05";
}
