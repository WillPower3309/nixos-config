{ config, pkgs, ... }:  

{
  users = {
    defaultUserShell = pkgs.zsh;
    users.will = {
      isNormalUser = true;
      extraGroups = [ "wheel" "libvirtd" "input" "kvm" "docker" ];
    };
  };
}
