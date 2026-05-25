{ inputs, ... }:

{
  flake.modules.homeManager.discord = { pkgs, ... }: {
    home = {
      packages = with pkgs; [ discord ];

      persistence."/nix/persist".directories = [ ".config/discord" ];
    };
  };
}
