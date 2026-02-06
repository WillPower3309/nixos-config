{ config, pkgs, nixosConfig, inputs, ... }:

{
  imports = [
    inputs.agenix.homeManagerModules.default
    inputs.impermanence.nixosModules.home-manager.impermanence
    #./modules/android-development.nix
    ./modules/cad.nix
    ./modules/discord.nix
    ./modules/document-viewer.nix
    ./modules/evolution-clients.nix
    ./modules/fetch.nix
    ./modules/foot.nix
    #./modules/gamedev.nix
    ./modules/games.nix
    ./modules/git.nix
    ./modules/music.nix
    #./modules/kde-connect.nix
    ./modules/keepass.nix
    ./modules/notetaking.nix
    ./modules/photography.nix
    ./modules/ssh-client.nix
    ./modules/theme.nix
    ./modules/sway.nix
    ./modules/video.nix
    ./modules/vim
    ./modules/zsh.nix
  ];

  programs.home-manager.enable = true;

  # TODO: already declared in nix.nix file, don't double declare
  nixpkgs.config.allowUnfree = true;

  xdg.mimeApps.enable = true;

  age.identityPaths = [ "/nix/persist/home/will/.ssh/id_ed25519" ];

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
        ".mozilla" # TODO: properly configure instead
      ];
    };

    stateVersion = nixosConfig.system.nixos.release;
  };
}
