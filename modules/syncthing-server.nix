{ pkgs, config, ... }:

let
  desktopDevice = "desktop";
  surfaceDevice = "surface";

  allDevices = [ desktopDevice surfaceDevice ];

in
{
  age.secrets = {
    serverSyncthingKey.file = ../secrets/serverSyncthingKey.age;
    serverSyncthingCert.file = ../secrets/serverSyncthingCert.age;
  };

  services.syncthing = {
    enable = true;
    dataDir = "/syncthing";
    openDefaultPorts = true;
    overrideDevices = true; # overrides any devices added or deleted through the WebUI
    overrideFolders = true; # overrides any folders added or deleted through the WebUI
    guiAddress = "0.0.0.0:8384";
    user = "root"; # TODO: proper perms for /data
    key = config.age.secrets.serverSyncthingKey.path;
    cert = config.age.secrets.serverSyncthingCert.path;

    settings = {
      options.urAccepted = -1;

      devices = {
        ${desktopDevice}.id = "QPGKBDU-6S4XWKH-DLNIZLR-RBRUSQ2-7RMMZS3-G2QB7RJ-ANZS36W-KTTAIQM";
        ${surfaceDevice}.id = "M5ENPZ2-OHBNDZO-XGUI444-LDR5VBD-ELEOO4H-JSCI35U-VHHSNDL-HBUMFAF";
      };

      folders = {
        "keepass" = {
          path = "/data/keepass";
          devices = allDevices;
        };
        "notes" = {
          path = "/data/notes";
          devices = allDevices;
        };
      };
    };
  };
  networking.firewall.allowedTCPPorts = [ 8384 ];
}
