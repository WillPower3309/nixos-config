{ pkgs, ... }:

{
  programs.waybar = {
    enable = true;

    settings = {
      primary = {
        layer = "top"; # Waybar at top layer
        position = "top"; # Waybar at the bottom of your screen
        height = 24;
        modules-left = ["sway/workspaces" "sway/mode"];
        modules-center = ["sway/window"];
        modules-right = ["pulseaudio" "network" "cpu" "memory" "battery" "tray" "clock"];
        "sway/workspaces" = {
          disable-scroll = true;
          all-outputs = false;
          format = "{icon}";
          format-icons = {
            "1:web" = "";
            "2:code" = "";
            "3:term" = "";
            "4:work" = "";
            "5:music" = "";
            "6:docs" = "";
            "urgent" = "";
            "focused" = "";
            "default" = "";
          };
        };
        "sway/mode" = {
          "format" = "<span style=\"italic\">{}</span>";
        };
        tray = {
          spacing = 10;
        };
        clock = {
          format-alt = "{:%Y-%m-%d}";
        };
        cpu = {
          format = "{usage}% ";
      };
        memory = {
          format = "{}% ";
        };
        battery = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{capacity}% {icon}";
          format-icons = ["" "" "" "" ""];
        };
        network = {
          format-wifi = "{essid} ({signalStrength}%) ";
          format-ethernet = "{ifname}: {ipaddr}/{cidr} ";
          format-disconnected = "Disconnected ⚠";
        };
        pulseaudio = {
          format = "{volume}% {icon}";
          format-bluetooth = "{volume}% {icon}";
          format-muted = "";
          format-icons = {
            headphones = "";
            handsfree = "";
            headset = "";
            phone = "";
            portable = "";
            car = "";
            default = ["" ""];
          };
          on-click = "pavucontrol";
        };
      };
    };

    style = ''
      * {
        border: none;
        border-radius: 0;
        font-family: "SF Pro Display Medium";
        font-size: 13px;
        min-height: 0;
      }

      window#waybar {
        background: transparent;
        color: white;
      }

      #window {
        font-weight: bold;
        font-family: "SF Pro Display";
      }

      #workspaces button {
        padding: 0 5px;
        background: transparent;
        color: white;
        border-top: 2px solid transparent;
      }

      #workspaces button.focused {
        color: #c9545d;
        border-top: 2px solid #c9545d;
      }

      #mode {
        background: #64727D;
        border-bottom: 3px solid white;
      }

      #clock, #battery, #cpu, #memory, #network, #pulseaudio, #custom-spotify, #tray, #mode {
        padding: 0 3px;
        margin: 0 2px;
      }

      #clock {
        font-weight: bold;
      }

      #battery {
      }

      #battery icon {
        color: red;
      }

      #battery.charging {
      }

      #battery.warning:not(.charging) {
        color: white;
        animation-name: blink;
        animation-duration: 0.5s;
        animation-timing-function: linear;
        animation-iteration-count: infinite;
        animation-direction: alternate;
      }

      #cpu {
      }

      #memory {
      }

      #network {
      }

      #network.disconnected {
        background: #f53c3c;
      }

      #pulseaudio {
      }

      #pulseaudio.muted {
      }

      #tray {
      }
    '';
  };
}
