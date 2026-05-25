{ pkgs, ... }:

{
  home = {
    packages = with pkgs; [
      blender
      freecad
      orca-slicer
    ];

    persistence."/nix/persist".directories = [ ".config/OrcaSlicer" ];
  };
}
