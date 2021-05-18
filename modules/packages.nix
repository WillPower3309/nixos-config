{ config, pkgs, ... }:

{
  imports = [];

  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraPackages = with pkgs; [
      swayidle
      xwayland
      waybar
      mako
      kanshi
      swaybg
      nwg-launchers
      autotiling
      brightnessctl
      slurp
      grim
    ];
  };
  

  programs.dconf.enable = true;
  

  environment.systemPackages = with pkgs; [
    alacritty
    qutebrowser
    discord
    neovim
    emacs
    pavucontrol
    git
    neofetch
    mpv
    youtube-dl
    pulseeffects-pw
    gnome3.nautilus
    nextcloud-client
    keepassxc
    ungoogled-chromium
    gcc
    valgrind
    gnumake
    virt-manager
    OVMF
    pciutils
    python
    nodejs
    pavucontrol
    spotify
    python3

    # gtk theming
    glib #gsettings command
    gtk-engine-murrine
    gtk_engines
    gsettings-desktop-schemas

    #arc-theme
    #tela-icon-theme

    #hybridbar
  ];
}
