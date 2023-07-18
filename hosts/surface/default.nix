{ config, pkgs, impermanence, flake-overlays, ... }:

{
  imports = [
    impermanence.nixosModules.impermanence
    ./hardware-configuration.nix
    ../../modules/nix.nix
    ../../modules/bootloader.nix
    ../../modules/kernel.nix
    ../../modules/greetd.nix
    ../../modules/bluetooth.nix
    ../../modules/sound.nix
    ../../modules/users.nix
    ../../modules/fonts.nix
    ../../modules/virtualization.nix
    ../../modules/music.nix
    ../../modules/development.nix
    ../../modules/packages.nix
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

  security.polkit.enable = true; # needed for sway

  environment.persistence."/nix/persist" = {
    hideMounts = true;
    directories = [ "/var/log" ];
    files = [ "/etc/machine-id" ]; # used by systemd for journalctl
  };

  system.stateVersion = "22.05";
}
