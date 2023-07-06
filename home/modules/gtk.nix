{ pkgs, ... }:

{
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
    cursorTheme = {
      name = "breeze_cursors";
      package = pkgs.breeze-gtk;
    };
  };
}
