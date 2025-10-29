{ config, ... }:

let baseDomain = "${config.networking.hostName}.willmckinnon.com";

in {
  services = {
    meshcentral = {
      enable = true;

      # options found at https://github.com/Ylianst/MeshCentral/blob/master/meshcentral-config-schema.json
      settings = {
        port = 4430;
      };
    };

    nginx.virtualHosts."meshcentral.${baseDomain}" = {
      useACMEHost = baseDomain;
      forceSSL = true;
      kTLS = true;
      locations."/".proxyPass = "http://localhost:${toString config.services.meshcentral.settings.port}";
    };
  };

#  environment.persistence."/persist".directories = [{
#    directory = "/var/lib/meshcentral";
#    user = "meshcentral";
#    group = "meshcentral";
#  }];
}

