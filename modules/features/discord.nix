{ inputs, ... }:

{
  flake.modules.homeManager.will = { pkgs, ... }: {
    home = {
      packages = with pkgs; [ discord ];

      persistence."/nix/persist".directories = [ ".config/discord" ];
    };
  };
}
