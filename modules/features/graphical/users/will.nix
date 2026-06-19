{ inputs, ... }:

{
  flake.modules.nixos.will-user = { config, pkgs, ... }: {
    imports = [
      inputs.agenix.nixosModules.age
      inputs.home-manager.nixosModules.home-manager
    ];

    age.secrets.hashedWillPassword.file = ./hashedWillPassword.age;

    users = {
      defaultUserShell = pkgs.zsh;
      users = {
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
      install -d -o will -g users ${config.constants.persistentDir}/will
    '';

    home-manager = {
      useUserPackages = true;
      backupFileExtension = "backup";
      users.will = {
        imports = [ inputs.self.modules.homeManager.will inputs.self.constants ];
      };
    };
  };

  flake.homeConfigurations = inputs.self.lib.mkHomeManager "x86_64-linux" "will";

  flake.modules.homeManager.will = { config, pkgs, lib, nixosConfig, ... }: {
    imports = [ inputs.agenix.homeManagerModules.default ];

    programs.home-manager.enable = true;
    nixpkgs.config.allowUnfree = true;

    xdg.mimeApps.enable = true;

    age.identityPaths = [ "${config.constants.persistentDir}/home/will/.ssh/id_ed25519" ];

    home = {
      username = "will";
      homeDirectory = "/home/will";

      persistence = {
        "${config.constants.persistentDir}".directories = [
          "Downloads"
          "Pictures"
          "Projects"
        ];
      };

      stateVersion = if nixosConfig == null then "26.05" else nixosConfig.system.nixos.release;
    };
  };
}
