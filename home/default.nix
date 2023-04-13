{ pkgs, impermanence, ... }:

{
  imports = [
    impermanence.nixosModules.home-manager.impermanence
    ./zsh.nix
    ./git.nix
    ./emacs.nix
  ];

  programs.home-manager.enable = true;

  home = {
    username = "will";
    homeDirectory = "/home/will";

    persistence = {
      "/nix/persist/home/will" = {
        directories = [
          "Downloads"
          "Projects"
          ".ssh"
          {
            directory = ".local/share/Steam ";
            method = "symlink";
          }
        ];

        allowOther = true;
      };
    };

    file = {
      ".config/sway/config".source = ./config/sway/config;
      ".config/foot/foot.ini".source =  ./config/foot/foot.ini;
      ".config/mpv/mpv.conf".source = ./config/mpv/mpv.conf;
      ".config/pipewire/pipewire.conf".source = ./config/pipewire/pipewire.conf;
      ".config/qutebrowser/config.py".source = ./config/qutebrowser/config.py;
    };

    stateVersion = "22.05";
  };
}
