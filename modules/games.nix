{ config, pkgs, ... }:

{
  programs.steam.enable = true;

  environment.systemPackages = with pkgs; [
    lutris
    gamemode
    minecraft
  ];
}
