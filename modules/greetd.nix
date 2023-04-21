{ pkgs, ... }:

let
  gtkgreet = "${pkgs.greetd.gtkgreet}/bin/gtkgreet";

  sway-kiosk = command: "${pkgs.sway}/bin/sway --config ${pkgs.writeText "kiosk.config" ''
    output * bg #000000 solid_color
    exec dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY SWAYSOCK
    exec "${command}; ${pkgs.sway}/bin/swaymsg exit"
  ''}";
in
{
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = sway-kiosk "${gtkgreet} -l -c '$SHELL -l'";
        user = "greeter";
      };
    };
  };
}
