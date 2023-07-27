{ pkgs, ... }:

{
  home.packages = with pkgs; [
    darktable
    imagemagick
  ];

  home.persistence."/nix/persist/home/will".directories = [ "Pictures/photography" ];
}
