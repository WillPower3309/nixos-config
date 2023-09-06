{ config, pkgs, impermanence, ... }:

{
  imports = [
    impermanence.nixosModules.impermanence
    ./hardware-configuration.nix
    ../../modules/bluetooth.nix
    ../../modules/bootloader.nix
    ../../modules/containerization.nix
    ../../modules/development.nix
    ../../modules/fonts.nix
    ../../modules/greetd.nix
    ../../modules/kernel.nix
    ../../modules/music.nix
    ../../modules/nix.nix
    ../../modules/packages.nix
    ../../modules/sound.nix
    ../../modules/syncthing.nix
    ../../modules/users.nix
    ../../modules/wifi.nix
  ];

  # Set your time zone.
  time.timeZone = "America/Toronto";

  networking.hostName = "surface";

  programs = {
    dconf.enable = true; # needed for sway
    light.enable = true; # laptop needs backlight
    fuse.userAllowOther = true; # persistence (TODO: make one file)
  };

  # needed for sway
  security.polkit.enable = true;
  xdg.portal = {
    enable = true;
    wlr.enable = true; # provides screen share
#    extraPortals = with pkgs; [
#      xdg-desktop-portal-gtk # provides file chooser
#    ];
  };

  environment.persistence."/nix/persist" = {
    hideMounts = true;
    directories = [ "/var/log" ];
    files = [ "/etc/machine-id" ]; # used by systemd for journalctl
  };

  system.stateVersion = "22.05";
}
