{ config, ... }:

let
  port = "5232";
  baseDomain = "${config.networking.hostName}.willmckinnon.com";
  address = "radicale.${baseDomain}";

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
        auth = {
          type = "htpasswd";
          htpasswd_filename = config.age.secrets.radicaleHtpasswd.path;
          htpasswd_encryption = "plain";
        };
        server.hosts = [ "0.0.0.0:${port}" "[::]:${port}" ];
        storage.filesystem_folder = "/data/radicale";
      };
    };

    nginx.virtualHosts."${address}" = {
      useACMEHost = baseDomain;
      forceSSL = true;
      kTLS = true;
      locations."/".proxyPass = "http://localhost:${port}";
    };
  };
}
