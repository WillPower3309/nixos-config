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

    # create persistent home directory owned by user
    system.activationScripts.persistent-user-dir-creation.text = ''
      install -d -o will -g users /nix/persist/home/will
    '';

    home-manager = {
      useUserPackages = true;
      extraSpecialArgs = { inherit inputs; };
      backupFileExtension = "backup";
      users.will = import ../../home;
    };
  };
}
