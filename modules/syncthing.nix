{ config, lib, ... }:

with config.networking;

let
  desktopDevice = "desktop";
  serverDevice = "server";
  surfaceDevice = "surface";
  phoneDevice = "phone";

  allDevices = [ desktopDevice serverDevice surfaceDevice phoneDevice ];

  # TODO: do not run as root
  syncthingUser = if hostName == "server" then "root" else "will";
  folderDir = if hostName == "server" then "/data" else "/nix/persist/home/${syncthingUser}";
  dataDir = if hostName == "server" then "/persist/syncthing" else folderDir;

  baseDomain = "${hostName}.willmckinnon.com";
  address = "syncthing.${baseDomain}";

  genDevice = hostName: id: { id = id; addresses = [ "tcp://${baseDomain}:22000" ]; };

# TODO: disable web gui?
in
{
  age.secrets = {
    syncthingKey.file = ./.. + builtins.toPath "/secrets/${hostName}SyncthingKey.age";
    syncthingCert.file = ./.. + builtins.toPath "/secrets/${hostName}SyncthingCert.age";
  };

  services = {
    syncthing = {
      enable = true;
      openDefaultPorts = true;
      overrideDevices = true; # overrides any devices added or deleted through the WebUI
      overrideFolders = true; # overrides any folders added or deleted through the WebUI
      user = syncthingUser;
      dataDir = dataDir;
      guiAddress = "0.0.0.0:8384";
      key = config.age.secrets.syncthingKey.path;
      cert = config.age.secrets.syncthingCert.path;

      settings = {
        options = {
          urAccepted = -1;
          localAccounceEnabled = false;
          relaysEnabled = true; # needed for connecting to phone
        };

        devices = {
          ${desktopDevice} = genDevice desktopDevice "QPGKBDU-6S4XWKH-DLNIZLR-RBRUSQ2-7RMMZS3-G2QB7RJ-ANZS36W-KTTAIQM";
          ${serverDevice} = genDevice serverDevice "V5AV6D5-5ITLYTL-35UHX6S-LKMFZ6U-FVGLEZP-EFGGR3R-O6AVGG7-ONT5MQE";
          ${surfaceDevice} = genDevice surfaceDevice "M5ENPZ2-OHBNDZO-XGUI444-LDR5VBD-ELEOO4H-JSCI35U-VHHSNDL-HBUMFAF";
          ${phoneDevice}.id = "F6DBZ2M-62WCNA7-GYD3LP3-4ODIDAQ-W6FMTHG-QN32HWG-AW4UXI5-6T6R6AP";
        };

        folders = {
          "keepass" = {
            path = "${folderDir}/keepass";
            devices = allDevices;
          };
          "notes" = {
            path = "${folderDir}/notes";
            devices = allDevices;
          };
        };
      };
    };

    nginx.virtualHosts."${address}" = lib.mkIf (hostName == "server") {
      useACMEHost = baseDomain;
      forceSSL = true;
      kTLS = true;
      locations."/".proxyPass = "http://localhost:8384";
    };
  };
}
