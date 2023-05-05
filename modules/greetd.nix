{ pkgs, ... }:

let
  swayKioskConfig = pkgs.writeText "kiosk.config" ''
    exec dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY SWAYSOCK
    exec "${pkgs.greetd.gtkgreet}/bin/gtkgreet -l; swaymsg exit"
  '';
in
{
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.sway}/bin/sway --config ${swayKioskConfig}";
        user = "greeter";
      };
    };
  };

  environment.etc = {
    "greetd/environments".text = ''
      dbus-run-session sway
      zsh
    '';
  };
}
