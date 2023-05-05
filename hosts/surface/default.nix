{ config, pkgs, impermanence, flake-overlays, ... }:

{
  imports = [
    impermanence.nixosModules.impermanence
    ./hardware-configuration.nix
    ../../modules/boot.nix
    ../../modules/kernel.nix
    ../../modules/greetd.nix
    ../../modules/sway.nix
    ../../modules/net.nix
    ../../modules/sound.nix
    ../../modules/users.nix
    ../../modules/fonts.nix
    ../../modules/virtualization.nix
    ../../modules/music.nix
    ../../modules/development.nix
    ../../modules/packages.nix
  ];

  # Set your time zone.
  time.timeZone = "America/Toronto";

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  nixpkgs = {
    # TODO: overlays
    # overlays = flake-overlays;
    config = {
      allowUnfree = true;
      oraclejdk.accept_license = true;
    };
  };

  programs = {
    light.enable = true; # laptop needs backlight
    fuse.userAllowOther = true; # persistence (TODO: make one file)
  };

  environment.persistence."/nix/persist" = {
    directories = [ "/var/log" ];
    files = [ "/etc/machine-id" ]; # used by systemd for journalctl
  };

  system.stateVersion = "22.05";
}
