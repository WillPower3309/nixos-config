{ inputs, ... }:

{
  flake.homeConfigurations = inputs.self.lib.mkHomeManager "x86_64-linux" "will";

  flake.modules.homeManager.will = { config, pkgs, nixosConfig, ... }: {
    imports = with inputs.self.modules.homeManager; [
      android-development
      cad
      discord
      document-viewer
      evolution-clients
      fetch
      foot
      gamedev
      games
      git
      kde-connect
      keepass
      music
      notetaking
      opencode
      photography
      ssh-client
      sway
      theme
      video
      vim
      zsh
    ] ++ [ inputs.agenix.homeManagerModules.default ];

    programs.home-manager.enable = true;

    # TODO: already declared in nix.nix file, don't double declare
    nixpkgs.config.allowUnfree = true;

    xdg.mimeApps.enable = true;

    age.identityPaths = [ "/nix/persist/home/will/.ssh/id_ed25519" ];

    home = {
      username = "will";
      homeDirectory = "/home/will";

      persistence."/nix/persist" = {
        directories = [
          "Downloads"
          "Pictures"
          "Projects"
          ".mozilla" # TODO: properly configure instead
        ];
      };

      stateVersion = nixosConfig.system.nixos.release;
    };
  };
}
