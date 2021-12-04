{ config, pkgs, ... }:

{  
  services.xserver = {
    enable = true;
    displayManager.gdm = {
      enable = true;
      wayland = true;
    };
  };

  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # LIBVA_DRIVER_NAME=iHD
      vaapiIntel         # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
      vaapiVdpau
      libvdpau-va-gl
    ];
  };

  fonts = {
    fonts = with pkgs; [
      roboto
      roboto-mono
      source-serif-pro
      meslo-lgs-nf
    ];

    fontconfig = {
      defaultFonts = {
        monospace = [ "Roboto Mono" ];
        sansSerif = [ "Roboto" ];
        serif     = [ "Source Serif Pro" ];
      };
    };
  };
}
