{ config, ... }:

let
  baseDomain = "${config.networking.hostName}.willmckinnon.com";
  endpoint = "freshrss.${baseDomain}";

in {
  age.secrets.freshrssAdminPassword = {
    file = ./../secrets/freshrssAdminPassword.age;
    owner = config.services.freshrss.user;
    group = config.users.users.${config.services.freshrss.user}.group;
  };

  services = {
    freshrss = {
      enable = true;
      baseUrl = "https://${endpoint}";
      dataDir = "/data/freshrss";
      webserver = "nginx";
      virtualHost = endpoint;
      authType = "form";
      passwordFile = config.age.secrets.freshrssAdminPassword.path;
    };

    # freshrss sets up some nginx config, add the ssl bits
    nginx.virtualHosts."${config.services.freshrss.virtualHost}" = {
      useACMEHost = baseDomain;
      forceSSL = true;
      kTLS = true;
    };
  };
}

