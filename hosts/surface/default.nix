{ config, pkgs, nixos-hardware, home-manager, flake-overlays, ... }:

{
  imports = [
    home-manager.nixosModules.home-manager
    ./hardware-configuration.nix
    ../../modules/boot.nix
    ../../modules/net.nix
    ../../modules/sound.nix
    ../../modules/users.nix
    ../../modules/sway.nix
    ../../modules/fonts.nix
    ../../modules/vim.nix
    ../../modules/music.nix
    ../../modules/development.nix
    ../../modules/games.nix
    ../../modules/packages.nix
  ];

  # Set your time zone.
  time.timeZone = "America/Toronto";

  # Laptop: Needs backlight
  environment.systemPackages = with pkgs; [
    brightnessctl
  ];

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
  };

  nixpkgs = {
    # TODO: overlays
    # overlays = flake-overlays;
    config = {
      allowUnfree = true;
      oraclejdk.accept_license = true;
    };
  };

  system.stateVersion = "22.05";
}
