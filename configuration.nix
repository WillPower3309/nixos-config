{ config, pkgs, lib, ... }:

{
  imports = [
    ./modules/boot.nix
    ./modules/filesystems.nix
    ./modules/users.nix
    ./modules/net.nix
    ./modules/sound.nix
    ./modules/graphical.nix
    ./modules/services.nix
    ./modules/packages.nix
  ];

  hardware.enableRedistributableFirmware = lib.mkDefault true;

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

#    nixPath = 
#      options.nix.nixPath.default ++ 
#      [ "nixpkgs-overlays=/etc/nixos/overlays/init.nix" ]
#    ;
  };

  nixpkgs.config = {
    allowUnfree = true;
    oraclejdk.accept_license = true;
  };

  nixpkgs.overlays = [
    #(import ./overlays/global-flags.nix)
    #(import ./overlays/package-flags.nix)
  ];

  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "America/Toronto";
  
  system.stateVersion = "20.09";
}

