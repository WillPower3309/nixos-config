{ pkgs, config, home-manager, impermanence, agenix, ... }:

{
  imports = [
    home-manager.nixosModules.home-manager
  ];

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

  home-manager = {
    useUserPackages = true;
    extraSpecialArgs = { inherit impermanence; };
    users.will = import ../home;
  };
}
