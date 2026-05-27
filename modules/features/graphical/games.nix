{
  flake.modules.nixos.games = {
    programs.steam.enable = true;
    hardware.graphics.enable32Bit = true; # needed for proton games
  };

  flake.modules.homeManager.will = { osConfig, pkgs, ... }: {
    home = {
      packages = with pkgs; [
        gamemode
        prismlauncher # minecraft launcher
      ];

      persistence."/nix/persist".directories = [
        ".local/share/Steam"
        ".minecraft"
      ];
    };
  };
}
