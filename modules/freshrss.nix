{ config, ... }:

let
  baseDomain = "${config.networking.hostName}.willmckinnon.com";
  endpoint = "freshrss.${baseDomain}";

in {
  services = {
    freshrss = {
      enable = true;
      baseUrl = "https://${endpoint}";
      dataDir = "/data/freshrss";
      webserver = "nginx";
      virtualHost = endpoint;
    };

    # freshrss sets up some nginx config, add the ssl bits
    nginx.virtualHosts."${config.services.freshrss.virtualHost}" = {
      useACMEHost = baseDomain;
      forceSSL = true;
      kTLS = true;
    };
  };
}

