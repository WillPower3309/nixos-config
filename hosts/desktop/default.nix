{ config, pkgs, impermanence, ... }:

{
  imports = [
    impermanence.nixosModules.impermanence
    ./hardware-configuration.nix
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
  ];

  # Set your time zone.
  time.timeZone = "America/Toronto";

  networking = {
    hostName = "desktop";
    wireless.enable = false;
  };

  programs = {
    dconf.enable = true; # needed for sway
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
