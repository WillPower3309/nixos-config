{ pkgs, ... }:

{
  programs.steam.enable = true;

  hardware.graphics.enable32Bit = true; # needed for proton games

  environment.systemPackages = with pkgs; [
    wineWowPackages.staging
    winetricks
    mono
  ];
}
