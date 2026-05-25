{ pkgs, config, ... }:

{
  # TODO: make me work
  home.pointerCursor = {
    enable = true;
    name = "breeze_cursors";
    package = pkgs.kdePackages.breeze-gtk;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
    sway.enable = true;
  };

  gtk = {
    enable = true;
    # TODO: font = {};
    theme = {
      name = "Arc-Dark";
      # TODO: gtkThemeFromScheme, manually defined w colors? (nix-colors)
      package = pkgs.arc-theme;
    };

    iconTheme = {
      name = "Tela";
      package = pkgs.tela-icon-theme;
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk";
  };
}

