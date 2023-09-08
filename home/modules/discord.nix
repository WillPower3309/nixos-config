{ pkgs, ... }:

{
  #programs.discocss = {
  #  enable = true;
  #  discordAlias = true;
  #};
  home = {
    packages = with pkgs; [ discord ];

    persistence."/nix/persist/home/will".directories = [ ".config/discord" ];
  };
  #xdg.configFile."discocss/custom.css".source = ./config/discocss/custom.css;
}
