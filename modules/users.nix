{ config, pkgs, ... }:  

{
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
}
