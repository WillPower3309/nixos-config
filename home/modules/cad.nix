{ pkgs, ... }:

{
  home = {
    packages = with pkgs; [
      blender
      freecad
      orca-slicer
    ];

    persistence."/nix/persist/home/will".directories = [ ".config/OrcaSlicer" ];
  };
}
