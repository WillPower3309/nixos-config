{ pkgs, ... }:

{
  services.plex = {
    enable = true;
    dataDir = "/data/plex";
    openFirewall = true;
  };
}
