{ pkgs, ... }:

{
  fonts = {
    fonts = with pkgs; [
      roboto
      roboto-mono
      source-serif-pro
      meslo-lgs-nf
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

