{
  flake.modules.nixos.games = {
    programs.steam.enable = true;
    hardware.graphics.enable32Bit = true; # needed for proton games
  };

  flake.modules.homeManager.will = { osConfig, pkgs, config, ... }: {
    home = {
      packages = with pkgs; [
        gamemode
        prismlauncher # minecraft launcher
      ];

      persistence."${config.constants.persistentDir}".directories = [
        ".local/share/Steam"
        ".minecraft"
      ];
    };
  };
}
