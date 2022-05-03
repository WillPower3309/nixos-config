{ config, pkgs, nixos-hardware, home-manager, flake-overlays, ... }:

{
  imports = [
    nixos-hardware.nixosModules.microsoft-surface
    home-manager.nixosModules.home-manager
    ./hardware-configuration.nix
    ../../modules/boot.nix
    ../../modules/net.nix
    ../../modules/sound.nix
    ../../modules/users.nix
    ../../modules/fonts.nix
    ../../modules/vim.nix
    ../../modules/music.nix
    ../../modules/development.nix
    ../../modules/packages.nix
  ];

  # Set your time zone.
  time.timeZone = "America/Toronto";

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.will = import ../../home;
  };

  services.xserver = {
    enable = true;
    displayManager.sddm.enable = true;
    desktopManager.plasma5.enable = true;
  };

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
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

