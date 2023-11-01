{ pkgs, impermanence, agenix, ... }:

{
  imports = [
    impermanence.nixosModules.home-manager.impermanence
    agenix.homeManagerModules.age
    ./modules/discord.nix
    ./modules/emacs.nix
    ./modules/foot.nix
    ./modules/games.nix
    ./modules/git.nix
    ./modules/gtk.nix
    ./modules/keepass.nix
    ./modules/kde-connect.nix
    ./modules/notetaking.nix
    ./modules/photography.nix
    ./modules/qt.nix
    ./modules/ssh-client.nix
    ./modules/sway.nix
    ./modules/video.nix
    ./modules/vim.nix
    ./modules/waybar.nix
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
