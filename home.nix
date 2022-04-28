{ pkgs, ... }:

{
  programs.home-manager.enable = true;

  home.packages = [];
  
  imports = [
    ./home-manager/emacs.nix
    ./home-manager/zsh.nix
  ];

  home.file = {
    ".config/sway/config".source = ./home-manager/additional-config/sway/config;
    ".config/oguri/config".source = ./home-manager/additional-config/oguri/config;
    ".config/foot/foot.ini".source = ./home-manager/additional-config/foot/foot.ini;
    ".config/mpv/mpv.conf".source = ./home-manager/additional-config/mpv/mpv.conf;
    ".config/pipewire/pipewire.conf".source = ./home-manager/additional-config/pipewire/pipewire.conf;
    ".config/qutebrowser/config.py".source = ./home-manager/additional-config/qutebrowser/config.py;
  };
}
