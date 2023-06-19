{ pkgs, impermanence, ... }:

{
  imports = [
    impermanence.nixosModules.home-manager.impermanence
    ./discord.nix
    ./emacs.nix
    ./games.nix
    ./git.nix
    ./gtk.nix
    ./kde-connect.nix
    ./qt.nix
    ./ssh-client.nix
    #./sway.nix
    ./video.nix
    ./vim.nix
    ./waybar.nix
    ./web-browsers.nix
    ./zsh.nix
  ];

  programs.home-manager.enable = true;

  # TODO: already declared in nix.nix file, don't double declare
  nixpkgs.config.allowUnfree = true;

  home = {
    username = "will";
    homeDirectory = "/home/will";

    persistence."/nix/persist/home/will" = {
      allowOther = true;
      directories = [
        "Downloads"
        "Pictures"
        "Projects"
        {
          directory = ".local/share/Steam ";
          method = "symlink";
        }
      ];
    };

    file = {
      ".config/sway/config".source =  ./config/sway/config;
      ".config/foot/foot.ini".source =  ./config/foot/foot.ini;
      ".config/pipewire/pipewire.conf".source = ./config/pipewire/pipewire.conf;
    };

    stateVersion = "22.05";
  };
}
