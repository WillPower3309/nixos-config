{ inputs, ... }:

{
  flake.modules.nixos.arr = { config, lib, ... }: let
    baseDomain = config.networking.fqdn;

    createNginxProxy = port: {
      locations."/".proxyPass = "http://${config.constants.loopbackAddr}:${builtins.toString port}";
      useACMEHost = baseDomain;
      forceSSL = true;
      kTLS = true;
    };

  in {
    services = {
      prowlarr = {
        enable = true;
        dataDir = "/persist/var/lib/prowlarr";
      };
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
      bazarr = {
        enable = true;
        dataDir = "/persist/var/lib/bazarr";
      };

      nginx.virtualHosts = {
        "prowlarr.${baseDomain}" = createNginxProxy config.services.prowlarr.settings.server.port;
        "sonarr.${baseDomain}" = createNginxProxy config.services.sonarr.settings.server.port;
        "radarr.${baseDomain}" = createNginxProxy config.services.radarr.settings.server.port;
        "readarr.${baseDomain}" = createNginxProxy config.services.readarr.settings.server.port;
        "bazarr.${baseDomain}" = createNginxProxy config.services.bazarr.listenPort;
      };
    };
  };
}
