{ inputs, ... }:

{
  flake.modules.nixos.meshcentral = { config, ... }: let baseDomain = config.networking.fqdn; in {
    services = {
      meshcentral = {
        enable = true;

        # options found at https://github.com/Ylianst/MeshCentral/blob/master/meshcentral-config-schema.json
        settings = {
          domains."".certUrl = "https://${config.constants.loopbackAddr}:${toString config.services.meshcentral.settings.settings.AliasPort}/";

          settings = {
            Cert = "meshcentral.${baseDomain}";
            Port = 4430;
            AliasPort = 443;
            RedirPort = 800;
            AgentPong = 300; # send data to agents every 300 seconds
            TlsOffload = config.constants.loopbackAddr;
          };
        };
      };

      nginx.virtualHosts."meshcentral.${baseDomain}" = {
        useACMEHost = baseDomain;
        forceSSL = true;
        kTLS = true;

        locations."/" = {
          proxyPass = "http://${config.constants.loopbackAddr}:${toString config.services.meshcentral.settings.settings.Port}";

          # 1. Allow websockets over HTTPS
          # 2. Use longer timeouts for websockets
          # 3. Inform MeshCentral of real host, port, and protocol
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

    environment.persistence."${config.constants.persistentDir}".directories = [{
      directory = "/var/lib/private/meshcentral";
      user = "meshcentral";
      group = "meshcentral";
    }];

    # Old Intel AMT firmware (no RFC 5746 secure renegotiation) is rejected by
    # modern OpenSSL by default, so allow legacy TLS renegotiation for this service only.
    systemd.services.meshcentral.serviceConfig.Environment = [
      "OPENSSL_CONF=/etc/openssl-meshcentral.cnf"
    ];

    environment.etc."openssl-meshcentral.cnf".text = ''
      openssl_conf = openssl_init

      [openssl_init]
      ssl_conf = ssl_sect

      [ssl_sect]
      system_default = system_default_sect

      [system_default_sect]
      MinProtocol = TLSv1
      CipherString = DEFAULT:@SECLEVEL=0
      Options = UnsafeLegacyRenegotiation
    '';
  };
}
