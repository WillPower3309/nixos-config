{ config, ... }:

let
  port = "5232";
  address = "radicale.${config.networking.hostName}.willmckinnon.com";

in
{
  age.secrets.radicaleHtpasswd = {
    file = ../secrets/radicaleHtpasswd.age;
    owner = "radicale";
    group = "radicale";
  };

  services = {
    radicale = {
      enable = true;
      settings = {
        server = {
          hosts = [ "0.0.0.0:${port}" "[::]:${port}" ];
        };
        auth = {
          type = "htpasswd";
          htpasswd_filename = config.age.secrets.radicaleHtpasswd.path;
          htpasswd_encryption = "plain";
        };
        storage = {
          filesystem_folder = "/data/radicale";
        };
      };
    };

    nginx.virtualHosts."${address}" = {
#      useACMEHost = address;
#      forceSSL = true;
#      kTLS = true;
      locations."/".proxyPass = "http://localhost:${port}";
    };
  };

#  security.acme.certs."${address}" = {};
}
