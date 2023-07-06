{ pkgs, lib, ... }:

{
  wayland.windowManager.sway = {
    enable = true;
    package = pkgs.swayfx;

    wrapperFeatures.gtk = true;

    extraSessionCommands = ''
      export _JAVA_AWT_WM_NONREPARENTING=1
    '';

    config = {
      # super key
      modifier = "Mod4";

      terminal = "footclient";
      menu = "nwggrid";

      bars = [{ command = "waybar"; }];

      gaps = {
        outer = 0;
        inner = 15;
      };

      # Disable mouse acceleration on desktop for all inputs
      # TODO: enable mouse acceleration for trackball
      # TODO if laptop: "input type:touchpad tap enabled"
      input = {
        "*" = {
          accel_profile = "flat";
          pointer_accel = "0";
        };
      };

      output = {
        "*".background = "~/Pictures/wallpaper.png fill";
      };

      seat.seat0 = {
        # TODO: pull xcursor theme from gtk.nix
        xcursor_theme = "breeze_cursors 10";
        hide_cursor = "3000";
      };

      startup = [
        { command = "foot --server"; }
        { command = "autotiling"; }
      ];

      keybindings = {
        # Audio
        #"XF86AudioRaiseVolume" = "exec set-volume inc 1";
        #"XF86AudioLowerVolume" = "exec set-volume dec 1";
        #"XF86AudioMute" = "exec set-volume toggle-mute";
        #"XF86AudioStop" = "exec ${pkgs.playerctl}/bin/playerctl stop";
        #"XF86AudioPrev" = "exec ${pkgs.playerctl}/bin/playerctl previous";
        #"XF86AudioNext" = "exec ${pkgs.playerctl}/bin/playerctl next";
        #"XF86AudioPlay" = "exec ${pkgs.playerctl}/bin/playerctl play-pause";

        # TODO: IF LAPTOP
        #"XF86MonBrightnessDown" = "exec brightnessctl set 15%-";
        #"XF86MonBrightnessUp" =  "exec brightnessctl set +15%";
      };
    };

    # SwayFX settings
    extraConfig = ''
      shadows on
      corner_radius 12
    '';
  };

  home = {
    packages = with pkgs; [
      swaybg
      waybar
      mako
      nwg-launchers
      autotiling
      slurp
      grim

      # TODO: use the below!
      # gammastep
      # swayidle
      # kanshi
    ];
  };
}
