{ inputs, ... }:

{
  flake.modules.homeManager.will = { pkgs, config, ... }: {
    home = {
      packages = with pkgs; [
        blender
        freecad
        orca-slicer
      ];

      persistence."${config.constants.persistentDir}".directories = [ ".config/OrcaSlicer" ];
    };
  };
}
