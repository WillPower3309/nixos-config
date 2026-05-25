{ inputs, ... }:

{
  flake.modules.homeManager.will = { pkgs, config, ... }: {
    home = {
      packages = with pkgs; [ discord ];

      persistence."${config.constants.persistentDir}".directories = [ ".config/discord" ];
    };
  };
}
