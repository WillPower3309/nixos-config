{ config, pkgs, impermanence, home-manager, ... }:

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

  # Enable the Plasma 5 Desktop Environment.
  services.xserver = {
    enable = true;
    videoDrivers = [ "nvidia" ];
    displayManager.sddm.enable = true;
    desktopManager.plasma5.enable = true;
  };

  environment.systemPackages = with pkgs; [
    libsForQt5.kwin-tiling
    latte-dock
  ];
  
  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';

    maxJobs = 1;
    buildCores = 4;

    gc = {
      automatic = true;
      dates = "thursday";
      options = "--delete-older-than 8d";
    };
  };

  nixpkgs = {
    overlays = (import ../../overlays/init.nix);
    config = {
      allowUnfree = true;
      oraclejdk.accept_license = true;
    };
  };

  system.stateVersion = "22.05";
}

