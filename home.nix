{ pkgs, ... }:

{
  programs.home-manager.enable = true;

  home.packages = [];
  
  imports = [
    ./home-manager/alacritty.nix
    ./home-manager/emacs.nix
    ./home-manager/zsh.nix
  ];

  home.file = {
    ".config/sway/config".source = ./home-manager/additional-config/sway/config;
  };
}
