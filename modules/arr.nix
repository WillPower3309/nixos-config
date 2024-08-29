{ config, lib, ... }:

let
  baseDomain = "${config.networking.hostName}.willmckinnon.com";

  createNginxProxy = port: {
    locations."/".proxyPass = "http://127.0.0.1:${port}";
    useACMEHost = baseDomain;
    forceSSL = true;
    kTLS = true;
  };

in
{
  services = {
    sonarr = {
      enable = true;
      dataDir = "/persist/var/lib/sonarr";
    };

    radarr = {
      enable = true;
      dataDir = "/persist/var/lib/radarr";
    };

    readarr = {
      enable = true;
      dataDir = "/persist/var/lib/readarr";
      user = if config.services.calibre-server.enable then config.services.calibre-server.user else "readarr";
    };

    prowlarr.enable = true;

    bazarr.enable = true;

    nginx.virtualHosts = {
      "sonarr.${baseDomain}" = createNginxProxy "8989";
      "radarr.${baseDomain}" = createNginxProxy "7878";
      "readarr.${baseDomain}" = createNginxProxy "8787";
      "prowlarr.${baseDomain}" = createNginxProxy "9696";
      "bazarr.${baseDomain}" = createNginxProxy "6767";
    };
  };

  # TODO: add below to prowlarr and bazarr module upstream
  environment.persistence."/persist".directories = [
    "/var/lib/prowlarr"
    "/var/lib/bazarr"
  ];
  systemd.services.prowlarr.serviceConfig.DynamicUser = lib.mkForce false;
  systemd.services.bazarr.serviceConfig.DynamicUser = lib.mkForce false;
}

