{ pkgs, impermanence, ... }:

{
  imports = [
    impermanence.nixosModules.home-manager.impermanence
    #./sway.nix
    ./gtk.nix
    ./qt.nix
    ./zsh.nix
    ./git.nix
    ./emacs.nix
    ./vim.nix
    ./web-browsers.nix
    ./games.nix
    ./discord.nix
    ./kde-connect.nix
  ];

  programs.home-manager.enable = true;

  # TODO: already declared in host file, don't double declare
  nixpkgs.config.allowUnfree = true;

  home = {
    username = "will";
    homeDirectory = "/home/will";

    persistence = {
      "/nix/persist/home/will" = {
        directories = [
          "Downloads"
          "Pictures"
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
      ".config/sway/config".source =  ./config/sway/config;
      ".config/foot/foot.ini".source =  ./config/foot/foot.ini;
      ".config/mpv/mpv.conf".source = ./config/mpv/mpv.conf;
      ".config/pipewire/pipewire.conf".source = ./config/pipewire/pipewire.conf;
    };

    stateVersion = "22.05";
  };
}
