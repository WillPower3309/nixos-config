{ pkgs, ... }:

{
  programs.home-manager.enable = true;

  home.packages = [
    pkgs.zsh
    pkgs.alacritty
  ];

  imports = [
    ./home-manager/zsh.nix
    ./home-manager/alacritty.nix
  ];
}
