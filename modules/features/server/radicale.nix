{ inputs, ... }:

{
  flake.modules.nixos.radicale = { config, ... }: let
    port = "5232";
    baseDomain = config.networking.fqdn;
    address = "radicale.${baseDomain}";
    dataDir = "/data/radicale";

  in {
    age.secrets.radicaleHtpasswd = {
      file = ./radicaleHtpasswd.age;
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
          storage.filesystem_folder = dataDir;
        };
      };

      nginx.virtualHosts."${address}" = {
        useACMEHost = baseDomain;
        forceSSL = true;
        kTLS = true;
        locations."/".proxyPass = "http://localhost:${port}";
      };
    };

    system.activationScripts.radicale-dir-creation.text = ''
      install -d -o radicale -g radicale ${dataDir}
    '';
  };
}
