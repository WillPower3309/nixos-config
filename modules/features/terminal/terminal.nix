{ inputs, ... }:

{
  flake.modules.homeManager.will = { config, pkgs, lib, ... }: {
    xdg = {
      desktopEntries = {
        "foot" = {
          name = "";
          settings.NoDisplay = "true";
        };
        "foot-server" = {
          name = "";
          settings.NoDisplay = "true";
        };
        "footclient".name = "Foot";
      };
      autostart.entries = lib.optionals config.xdg.autostart.enable [ "${pkgs.foot}/share/applications/foot-server.desktop" ];
    };

    programs.foot = {
      enable = true;

      settings = {
        main = {
          font = lib.mkForce "MesloLGS NF:size=10";
          dpi-aware = lib.mkForce "yes";
        };

        cursor = {
          style = "block";
          blink = "no";
        };

        mouse.hide-when-typing = "yes";

        colors-dark = {
          alpha = lib.mkForce "0.8";
          cursor = "2e3440 d8dee9";
          foreground = "eceff4";
          background = "2e3440";
          regular0 = "3b4252";
          regular1 = "bf616a";
          regular2 = "a3be8c";
          regular3 = "ebcb8b";
          regular4 = "81a1c1";
          regular5 = "b48ead";
          regular6 = "88c0d0";
          regular7 = "e5e9f0";
          bright0 = "4c566a";
          bright1 = "bf616a";
          bright2 = "a3be8c";
          bright3 = "ebcb8b";
          bright4 = "81a1c1";
          bright5 = "b48ead";
          bright6 = "8fbcbb";
          bright7 = "eceff4";
        };
      };
    };
  };
}
