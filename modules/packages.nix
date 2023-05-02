{ config, pkgs, ... }:

{
  imports = [];

  programs.steam.enable = true;

  environment.systemPackages = with pkgs; [
    neofetch
    mpv
    youtube-dl
    keepassxc
    pciutils
    colorls
    nextcloud-client
    unzip
    gtop
    foot

    libnotify

    gnome3.nautilus
    openssl

    ripgrep

    imagemagick

    ani-cli

    udiskie

    obs-studio

    tutanota-desktop

    psmisc # fuser, killall and pstree etc

    wineWowPackages.staging

    # winetricks and other programs depending on wine need to use the same wine version
    winetricks
    mono

    python39Packages.psutil

    darktable
  ];
}
