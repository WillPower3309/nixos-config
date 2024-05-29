{ pkgs, config, home-manager, impermanence, agenix, ags, stylix, ... }:

{
  imports = [ home-manager.nixosModules.home-manager ];

  programs.zsh.enable = true;

  age.secrets = {
    hashedWillPassword.file = ../secrets/hashedWillPassword.age;
    hashedRootPassword.file = ../secrets/hashedRootPassword.age;
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
    extraSpecialArgs = { inherit impermanence agenix ags stylix; };
    backupFileExtension = "backup";
    users.will = import ../home;
  };
}
