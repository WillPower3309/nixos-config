{ pkgs, ... }:

{
  xdg.portal.wlr.enable = true;

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
    ];
  };
}

