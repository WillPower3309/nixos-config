{ pkgs, ... }:

# TODO: gtkgreet spawn delay
let
  gtkgreetCssEtcPath = "greetd/gtkgreet.css";
in
{
  services.greetd = {
    enable = true;
    settings = {
      default_session.command = "${pkgs.cage}/bin/cage -d -- ${pkgs.greetd.gtkgreet}/bin/gtkgreet -s /etc/${gtkgreetCssEtcPath}";
    };
  };

  environment.etc = {
    "greetd/environments".text = ''
      sway
      zsh
    '';

    # TODO: have wallpaper / colors / corner radius apply here and to sway config (we should have some coupling here, nix-colors?)
    # TODO: should we have wallpaper in a persisted assets folder? Could also have a blurred portion for the box portion of the css
    "${gtkgreetCssEtcPath}".text = ''
      window {
        background-image: url("file:///nix/persist/home/will/Pictures/wallpaper.png");
        background-size: cover;
        background-position: center;
      }

      box#body {
        background-color: rgba(50, 50, 50, 0.5);
        border-radius: 10px;
        padding: 50px;
      }
    '';
  };
}
