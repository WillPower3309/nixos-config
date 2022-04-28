{ config, pkgs, ... }:

{
  imports = [];

  environment.systemPackages = with pkgs; [
    qutebrowser
    discord
    neofetch
    mpv
    youtube-dl
    keepassxc
    ungoogled-chromium
    pciutils
    colorls
    nextcloud-client
    unzip
    gtop
    foot
    zsh

    # gtk theming
    glib #gsettings command
    gtk-engine-murrine
    gtk_engines
    gsettings-desktop-schemas
    # theming
    arc-theme
    tela-icon-theme
    breeze-gtk

    libnotify

    gnome3.nautilus
    openssl

    ripgrep

    imagemagick

    nur.repos.willpower3309.ani-cli

    udiskie

    zoom-us

    obs-studio

    tutanota-desktop

    psmisc # fuser, killall and pstree etc

    wineWowPackages.staging

    # winetricks and other programs depending on wine need to use the same wine version
    winetricks
    mono

    libreoffice

    teams
    openconnect
    remmina
    audacity

    python39Packages.psutil

    jdk
  ];
}

