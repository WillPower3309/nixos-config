{ config, pkgs, ... }:

{
  programs.steam.enable = true;

  environment.systemPackages = with pkgs; [
    neofetch
    keepassxc
    pciutils
    colorls
    unzip
    gtop

    libnotify

    gnome3.nautilus
    openssl

    ripgrep

    udiskie

    tutanota-desktop

    psmisc # fuser, killall and pstree etc

    wineWowPackages.staging
    # winetricks and other programs depending on wine need to use the same wine version
    winetricks
    mono

    python39Packages.psutil
  ];
  services.udisks2.enable = true;
}
