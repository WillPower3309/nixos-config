{ pkgs, ... }:

{
  programs.foot = {
    enable = true;
    # TODO: server.enable

    settings = {
      main = {
        font = "MesloLGS NF:size=10";
        dpi-aware = "yes";
      };

      cursor = {
        style = "block";
        color = "2e3440 d8dee9";
        blink = "no";
      };

      mouse.hide-when-typing = "yes";

      colors = {
        alpha = "0.8";
        foreground = "eceff4";
        background = "2e3440";
        regular0 = "3b4252";  # black
        regular1 = "bf616a";  # red
        regular2 = "a3be8c";  # green
        regular3 = "ebcb8b";  # yellow
        regular4 = "81a1c1";  # blue
        regular5 = "b48ead";  # magenta
        regular6 = "88c0d0";  # cyan
        regular7 = "e5e9f0";  # white
        bright0 = "4c566a";   # bright black
        bright1 = "bf616a";   # bright red
        bright2 = "a3be8c";   # bright green
        bright3 = "ebcb8b";   # bright yellow
        bright4 = "81a1c1";   # bright blue
        bright5 = "b48ead";   # bright magenta
        bright6 = "8fbcbb";   # bright cyan
        bright7 = "eceff4";   # bright white
      };
    };
  };
}
