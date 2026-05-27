{ inputs, ... }:

{
  flake.modules.nixos.users = { config, pkgs, ... }: {
    imports = [
      inputs.agenix.nixosModules.age
      inputs.home-manager.nixosModules.home-manager
    ];

    age.secrets = {
      hashedWillPassword.file = "${inputs.secrets}/hashedWillPassword.age";
      hashedRootPassword.file = "${inputs.secrets}/hashedRootPassword.age";
    };

    users = {
      mutableUsers = false;
      defaultUserShell = pkgs.zsh;

      users = {
        root.hashedPasswordFile = config.age.secrets.hashedRootPassword.path;

        will = {
          isNormalUser = true;
          hashedPasswordFile = config.age.secrets.hashedWillPassword.path;
          extraGroups = [ "wheel" "libvirtd" "input" "kvm" "docker" "video" ];
        };
      };
    };

    programs.zsh.enable = config.users.defaultUserShell == pkgs.zsh;

    # create persistent home directory owned by user
    system.activationScripts.persistent-user-dir-creation.text = ''
      install -d -o will -g users ${config.constants.persistentDir}/home/will
    '';

    home-manager = {
      useUserPackages = true;
      backupFileExtension = "backup";
      sharedModules = [ inputs.self.constants ];
      users.will = {
        imports = [ inputs.self.modules.homeManager.will ];
      };
    };
  };

  flake.homeConfigurations = inputs.self.lib.mkHomeManager "x86_64-linux" "will";

  flake.modules.homeManager.will = { config, pkgs, nixosConfig, ... }: {
    imports = [ inputs.agenix.homeManagerModules.default ];

    programs.home-manager.enable = true;

    # TODO: already declared in nix.nix file, don't double declare
    nixpkgs.config.allowUnfree = true;

    xdg.mimeApps.enable = true;

    age.identityPaths = [ "${config.constants.persistentDir}/home/will/.ssh/id_ed25519" ];

    home = {
      username = "will";
      homeDirectory = "/home/will";

      persistence."${config.constants.persistentDir}" = {
        directories = [
          "Downloads"
          "Pictures"
          "Projects"
        ];
      };

      stateVersion = if nixosConfig == null then "26.05" else nixosConfig.system.nixos.release;
    };
  };
}
