{ pkgs, config, home-manager, impermanence, ... }:

{
  imports = [
    home-manager.nixosModules.home-manager
  ];

  programs.zsh.enable = true;

  users = {
    mutableUsers = false;
    defaultUserShell = pkgs.zsh;

    users = {
      root = {
        initialPassword = "1012917";
      };
      will = {
        isNormalUser = true;
        initialPassword = "1012917";
        extraGroups = [ "wheel" "libvirtd" "input" "kvm" "docker" ];
      };
    };
  };

  home-manager = {
    useUserPackages = true;
    extraSpecialArgs = { inherit impermanence; };
    users.will = import ../home;
  };
}
