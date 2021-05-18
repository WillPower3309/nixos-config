{ config, pkgs, ... }:

{  
  services.xserver.enable = false;

  fonts = {
    fonts = with pkgs; [
      roboto
      roboto-mono
      source-serif-pro
    ];

    fontconfig = {
      defaultFonts = {
        monospace = [ "Roboto Mono" ];
        sansSerif = [ "Roboto" ];
        serif     = [ "Source Serif Pro" ];
      };
    };
  };
}
