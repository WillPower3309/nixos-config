{ pkgs, stylix, ... }:

let
  opacity = 0.8;
  fontSize = 11;

in
{
  imports = [ stylix.homeModules.stylix ];

  stylix = {
    enable = true;
    image = ../assets/wallpaper.png;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/nord.yaml";
    polarity = "dark";

    opacity = {
      terminal = opacity;
      popups = opacity;
    };

    fonts.sizes = {
      applications = fontSize;
      desktop = fontSize;
      popups = fontSize;
    };

    cursor = {
      name = "breeze_cursors";
      package = pkgs.kdePackages.breeze-gtk;
      size = 10;
    };

    targets.sway.enable = false;
  };

  gtk.iconTheme = {
    name = "Tela";
    package = pkgs.tela-icon-theme;
  };
}

