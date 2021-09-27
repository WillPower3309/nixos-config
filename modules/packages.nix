{ config, pkgs, ... }:

{
  imports = [];

  programs.dconf.enable = true;

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
  
  environment.systemPackages = with pkgs; [
    qutebrowser
    discord
    neovim
    pavucontrol
    git
    neofetch
    mpv
    youtube-dl
    pulseeffects-pw
    keepassxc
    ungoogled-chromium
    virt-manager
    OVMF
    pciutils
    python
    nodejs
    pavucontrol
    spotify
    python3
    colorls
    obs-studio
    nextcloud-client
    unzip
    gtop
    alacritty
    zsh

    # theming
    arc-theme
    tela-icon-theme

    #wayfire
    #wcm
    #swayfire
    #hybridbar
    slurp
    grim

    mono
    wineWowPackages.stable
    (winetricks.override { wine = wineWowPackages.staging; })
    steam

    mpd
    ncmpcpp
    mpc_cli
    libnotify

    gnome3.nautilus
    lutris
    openssl

    ripgrep

    runelite
  ];
}
