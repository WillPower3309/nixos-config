{ pkgs, ... }:

{
  programs.fastfetch = {
    enable = true;
    settings = {
      logo = {
        source = "nixos_small";
        padding = {
          right = 1;
        };
      };
      display = {
        separator = "  ";
        key.type = "icon";
      };
      modules = [
        {
          type = "host";
          key = "host";
          format = "{1}";
        }
        {
          type = "os";
          key = "os";
          format = "{name}";
        }
        {
          type = "shell";
          key = "shell";
          format = "{1}";
        }
        {
          type = "memory";
          key = "ram";
          format = "{1}/{2}";
        }
        {
          type = "media";
          key = "playing";
        }
        {
          type = "uptime";
          key = "uptime";
        }
        {
          type = "battery";
          key = "charge";
          format = "{4} {5}";
        }
        "break"
        {
          type = "colors";
          symbol = "circle";
          paddingleft = 5;
        }
      ];
    };
  };
}

