{ config, pkgs, impermanence, home-manager, flake-overlays, ... }:

{
  imports = [
    impermanence.nixosModules.impermanence
    home-manager.nixosModules.home-manager
    ./hardware-configuration.nix
    ../../modules/boot.nix
    ../../modules/kernel.nix
    ../../modules/net.nix
    ../../modules/sound.nix
    ../../modules/users.nix
    ../../modules/sway.nix
    ../../modules/fonts.nix
    ../../modules/vim.nix
    ../../modules/music.nix
    ../../modules/games.nix
    ../../modules/development.nix
    ../../modules/virtualization.nix
    ../../modules/packages.nix
  ];

  # Set your time zone.
  time.timeZone = "America/Toronto";

  environment.persistence."/nix/persist" = import ./persistence.nix;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.will = import ../../home;
  };

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';

    gc = {
      automatic = true;
      dates = "thursday";
      options = "--delete-older-than 8d";
    };
  };

  nixpkgs = {
    overlays = flake-overlays;
    config = {
      allowUnfree = true;
      oraclejdk.accept_license = true;
    };
  };

  system.stateVersion = "22.05";
}

