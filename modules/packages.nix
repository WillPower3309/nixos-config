{ config, pkgs, ... }:

{
  imports = [];

  programs.steam.enable = true;

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
      oguri
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
    foot
    zsh

    # theming
    arc-theme
    tela-icon-theme
    breeze-gtk

    #hybridbar

    mono
    wine
    winetricks

    mpd
    ncmpcpp
    mpc_cli
    libnotify

    gnome3.nautilus
    openssl

    ripgrep

    imagemagick

    lutris
    gamemode

    swaybg
    nur.repos.willpower3309.ani-cli
  ];
}
