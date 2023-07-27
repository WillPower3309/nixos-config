{ config, pkgs, impermanence, ... }:

{
  imports = [
    impermanence.nixosModules.impermanence
    ./hardware-configuration.nix
    ../../modules/nix.nix
    ../../modules/bootloader.nix
    ../../modules/kernel.nix
    ../../modules/greetd.nix
    ../../modules/sound.nix
    ../../modules/users.nix
    ../../modules/fonts.nix
    ../../modules/music.nix
    ../../modules/development.nix
    ../../modules/virtualization.nix
    ../../modules/packages.nix
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
