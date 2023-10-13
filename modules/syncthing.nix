{ pkgs, config, ... }:

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
        desktop.id = "QPGKBDU-6S4XWKH-DLNIZLR-RBRUSQ2-7RMMZS3-G2QB7RJ-ANZS36W-KTTAIQM";
      };

      folders = {
        "keepass" = {
          path = "/data/keepass";
          devices = [ "desktop" ];
        };
      };
    };
  };
  networking.firewall.allowedTCPPorts = [ 8384 ];
}
