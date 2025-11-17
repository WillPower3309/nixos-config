{ pkgs, ... }:

{
  home = {
    packages = with pkgs; [ discord ];

    persistence."/nix/persist/home/will".directories = [ ".config/discord" ];
  };
}
