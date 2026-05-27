{ inputs, ... }:

{
  flake.modules.homeManager.will = { pkgs, config, ... }: {
    home = {
      packages = [ pkgs.obsidian ];

      persistence."${config.constants.persistentDir}".directories = [
        "notes"
        # TODO: replace below with declarative config
        ".config/obsidian"
      ];
    };
  };
}
