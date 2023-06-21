{ config, pkgs, impermanence, flake-overlays, ... }:

{
  imports = [
    impermanence.nixosModules.impermanence
    ./hardware-configuration.nix
    ../../modules/nix.nix
    ../../modules/bootloader.nix
    ../../modules/kernel.nix
    ../../modules/greetd.nix
    ../../modules/sway.nix
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

  # persistence (TODO: make one file)
  programs.fuse.userAllowOther = true;

  environment.persistence."/nix/persist" = {
    hideMounts = true;
    directories = [ "/var/log" ];
    files = [ "/etc/machine-id" ]; # used by systemd for journalctl
  };

  system.stateVersion = "22.05";
}
