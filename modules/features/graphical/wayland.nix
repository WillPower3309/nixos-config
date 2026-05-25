{
  flake.modules.nixos.wayland = {
    xdg.portal = {
      enable = true;
      wlr.enable = true; # provides screen share
      config.common.default = [ "wlr" ];
    };

    environment.variables = {
      _JAVA_AWT_WM_NONREPARENTING = "1";
      QT_QPA_PLATFORM = "wayland";
      XDG_CURRENT_DESKTOP = "sway";
      NIXOS_OZONE_WL = "1";
      GDK_BACKEND = "wayland";
    };
  };
}
