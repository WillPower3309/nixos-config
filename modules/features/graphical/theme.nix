{ inputs, ... }:

{
  flake.modules.homeManager.will = { pkgs, config, ... }: {
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
      # TODO: theme: gtkThemeFromScheme, manually defined w colors? (nix-colors)

      iconTheme = {
        name = "Tela";
        package = pkgs.tela-icon-theme;
      };
    };

    qt = {
      enable = true;
      platformTheme.name = "gtk3";
    };
  };
}
