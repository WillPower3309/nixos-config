{ pkgs, impermanence, agenix, ags, ... }:

{
  imports = [
    agenix.homeManagerModules.age
    ags.homeManagerModules.default
    impermanence.nixosModules.home-manager.impermanence
    ./modules/android-development.nix
    ./modules/ags.nix
    ./modules/cad.nix
    ./modules/discord.nix
    ./modules/document-viewer.nix
    ./modules/emacs.nix
    ./modules/evolution-clients.nix
    ./modules/foot.nix
    ./modules/gamedev.nix
    ./modules/games.nix
    ./modules/git.nix
    ./modules/music.nix
    ./modules/kde-connect.nix
    ./modules/keepass.nix
    ./modules/notetaking.nix
    ./modules/photography.nix
    ./modules/ssh-client.nix
    ./modules/theme.nix
    ./modules/sway.nix
    ./modules/video.nix
    ./modules/vim.nix
    ./modules/web-browsers.nix
    ./modules/zsh.nix
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

    file.".config/pipewire/pipewire.conf".source = ./modules/config/pipewire/pipewire.conf;

    stateVersion = "22.05";
  };
}
