{ pkgs, ... }:

{
  home = {
    packages = with pkgs; [ ags ];
    xdg.configFile."ags".source = ./config/ags;
  };
}
