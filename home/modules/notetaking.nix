{ pkgs, ... }:

{
  home = {
    packages = [ pkgs.obsidian ];
    persistence."/nix/persist/home/will".directories = [ "Notes" ];
  };
}
