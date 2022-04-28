{ config, pkgs, ... }:  

{
  users = {
    mutableUsers = false;
    defaultUserShell = pkgs.zsh;

    users = {
      root = {
        initialPassword = "NICE TRY";
      };
      will = {
        isNormalUser = true;
        initialPassword = "NICE TRY";
        extraGroups = [ "wheel" "libvirtd" "input" "kvm" "docker" ];
      };
    };
  };
}
