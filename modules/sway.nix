{ pkgs, ... }:

{
  xdg.portal.wlr.enable = true;

  boot.plymouth.enable = true;

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd sway";
        user = "greeter";
      };
    };
  };

  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;

    extraSessionCommands = ''
      export _JAVA_AWT_WM_NONREPARENTING=1
    '';

    extraPackages = with pkgs; [
      swayidle
      xwayland
      waybar  
      mako    
      kanshi
      swaybg 
      nwg-launchers   
      autotiling
      slurp  
      grim
      oguri    
      gammastep
    ];
  };
}

