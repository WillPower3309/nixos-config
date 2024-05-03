{ pkgs, ... }:

{
  gtk = {
    enable = true;
    # TODO: font = {};
    theme = {
      name = "Adwaita-dark";
      # TODO: gtkThemeFromScheme, manually defined w colors? (nix-colors)
    };
    iconTheme = {
      name = "Tela";
      package = pkgs.tela-icon-theme;
    };
    cursorTheme = {
      name = "breeze_cursors";
      package = pkgs.breeze-gtk;
    };

    gtk3.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };

    gtk4.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };
  };

  dconf = {
    enable = true;
    settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
  };
}
