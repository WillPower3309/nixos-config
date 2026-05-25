{ inputs, ... }:

{
  flake.modules.nixos.meshcentral = { config, ... }: let
    baseDomain = config.networking.fqdn;

  in {
    services = {
      meshcentral = {
        enable = true;

        settings = {
          domains."".certUrl = "https://127.0.0.1:${toString config.services.meshcentral.settings.settings.AliasPort}/";

          settings = {
            Cert = "meshcentral.${baseDomain}";
            Port = 4430;
            AliasPort = 443;
            RedirPort = 800;
            AgentPong = 300;
            TlsOffload = "127.0.0.1";
          };
        };
      };

      nginx.virtualHosts."meshcentral.${baseDomain}" = {
        useACMEHost = baseDomain;
        forceSSL = true;
        kTLS = true;

        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString config.services.meshcentral.settings.settings.Port}";

          extraConfig = ''
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;

            proxy_set_header X-Forwarded-Host $host:$server_port;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };

        extraConfig = ''
          proxy_send_timeout ${toString (config.services.meshcentral.settings.settings.AgentPong + 30)};
          proxy_read_timeout ${toString (config.services.meshcentral.settings.settings.AgentPong + 30)};
        '';
      };
    };

    environment.persistence."/nix/persist".directories = [{
      directory = "/var/lib/private/meshcentral";
      user = "meshcentral";
      group = "meshcentral";
    }];
  };
}
