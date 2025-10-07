{ pkgs, ... }:

{
  programs.steam.enable = true;

  environment.systemPackages = with pkgs; [
    pciutils
    colorls
    gtop

    libnotify

    tutanota-desktop

    psmisc # fuser, killall and pstree etc

    wineWowPackages.staging
    # winetricks and other programs depending on wine need to use the same wine version
    winetricks
    mono
  ];
}
