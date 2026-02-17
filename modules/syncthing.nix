{ config, lib, ... }:

let
  desktopDevice = "desktop";
  laptopDevice = "laptop";
  serverDevice = "server";
  phoneDevice = "phone";

  allDevices = [ desktopDevice laptopDevice serverDevice phoneDevice ];

  # TODO: do not run as root
  syncthingUser = if config.networking.hostName == "server" then "root" else "will";
  folderDir = if config.networking.hostName == "server" then "/data" else "/nix/persist/home/${syncthingUser}";
  dataDir = if config.networking.hostName == "server" then "/persist/syncthing" else folderDir;

  baseDomain = "willmckinnon.com";

  genDevice = hostName: id: { id = id; addresses = [ "tcp://${hostName}.${baseDomain}:22000" ]; };

# TODO: disable web gui?
in
{
  age.secrets = {
    syncthingKey.file = ./.. + builtins.toPath "/secrets/${config.networking.hostName}SyncthingKey.age";
    syncthingCert.file = ./.. + builtins.toPath "/secrets/${config.networking.hostName}SyncthingCert.age";
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
          ${laptopDevice} = genDevice laptopDevice "TZHR5AI-RWOKMDR-RMZVPR5-3YF3HF5-FTADDX3-GDFYKEY-U6NK3RY-NQKLKA3";
          ${serverDevice} = genDevice serverDevice "V5AV6D5-5ITLYTL-35UHX6S-LKMFZ6U-FVGLEZP-EFGGR3R-O6AVGG7-ONT5MQE";
          ${phoneDevice}.id = "22P2DVT-2OVRU5H-RW62AKV-RXDHIZW-7UXS7KE-UEBLEQT-FXYBNRK-M4PX5QE";
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

    nginx.virtualHosts."syncthing.${config.networking.hostName}.${baseDomain}" = lib.mkIf (config.networking.hostName == "server") {
      useACMEHost = "${config.networking.hostName}.${baseDomain}";
      forceSSL = true;
      kTLS = true;
      locations."/".proxyPass = "http://localhost:8384";
    };
  };
}
