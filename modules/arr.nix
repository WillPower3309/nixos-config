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
    prowlarr.enable = true;

    sonarr = {
      enable = true;
      dataDir = "/persist/var/lib/sonarr";
    };

    radarr = {
      enable = true;
      dataDir = "/persist/var/lib/radarr";
    };

    nginx.virtualHosts = {
      "prowlarr.${baseDomain}" = createNginxProxy "9696";
      "sonarr.${baseDomain}" = createNginxProxy "8989";
      "radarr.${baseDomain}" = createNginxProxy "7878";
    };
  };

  # TODO: add below to prowlarr module upstream
  environment.persistence."/persist".directories = [ "/var/lib/prowlarr" ];
  systemd.services.prowlarr.serviceConfig.DynamicUser = lib.mkForce false;
}

