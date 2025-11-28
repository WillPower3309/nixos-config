{ pkgs, ... }:

{
  fonts = {
    packages = with pkgs; [
      roboto
      roboto-mono
      source-serif-pro
      meslo-lgs-nf
      material-symbols
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

