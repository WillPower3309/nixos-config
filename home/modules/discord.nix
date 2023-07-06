{ pkgs, ... }:

{
  programs.discocss = {
    enable = true;
    discordAlias = true;
  };

  home.persistence."/nix/persist/home/will".directories = [ ".config/discord" ];

  xdg.configFile."discocss/custom.css".source = ./config/discocss/custom.css;
}
