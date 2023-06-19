{ pkgs, ... }:

{
  programs.ssh = {
    enable = true;
  };

  home.persistence."/nix/persist/home/will".directories = [ ".ssh" ];
}
