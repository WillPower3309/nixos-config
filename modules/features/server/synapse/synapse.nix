{ inputs, ... }:

{
  flake.modules.nixos.synapse = { config, pkgs, ... }: let
    baseDomain = "${config.networking.fqdn}";
    address = "synapse.${baseDomain}";
    clientPort = 8008;
    # TODO: add upstream option
    heisenbridgeRegistrationFilePath = "/var/lib/heisenbridge/registration.yml";

  in {
    imports = [ inputs.self.modules.nixos.postgresql ];

    age.secrets.synapseSharedSecret = {
      file = ./synapseSharedSecret.age;
      owner = "matrix-synapse";
      group = "matrix-synapse";
    };

    services = {
      matrix-synapse = {
        enable = true;
        dataDir = "/data/matrix-homeserver";
        extraConfigFiles = [ config.age.secrets.synapseSharedSecret.path ];

        settings = {
          server_name = baseDomain;
          public_baseurl = "https://${address}";
          tls_certificate_path = "/var/lib/acme/${baseDomain}/fullchain.pem";
          tls_private_key_path = "/var/lib/acme/${baseDomain}/key.pem";
          media_store_path = "${config.services.matrix-synapse.dataDir}/media";
          max_upload_size = "100M";
          app_service_config_files = [ heisenbridgeRegistrationFilePath ];

          listeners = [{
            bind_addresses = [ config.constants.loopbackAddr ];
            port = clientPort;
            resources = [{
              compress = true;
              names = [ "client" ];
            }];
            tls = false;
            type = "http";
            x_forwarded = true;
          }];
        };
      };

      # TODO: finish me: https://wiki.nixos.org/wiki/Matrix#Application_services_(a.k.a._bridges)
      mautrix-meta = { };

      heisenbridge = {
        enable = true;
        homeserver = "http://localhost:${toString clientPort}";
      };

      postgresql = {
        # TODO: ensureDatabases config upstream to replace initialScript
        ensureUsers = [{
          name = config.services.matrix-synapse.settings.database.args.user;
          ensureClauses = { login = true; };
        }];
        initialScript = pkgs.writeText "synapse-init.sql" ''
          CREATE ROLE "${config.services.matrix-synapse.settings.database.args.user}";
          CREATE DATABASE "${config.services.matrix-synapse.settings.database.args.database}"
            WITH OWNER "${config.services.matrix-synapse.settings.database.args.user}"
            TEMPLATE template0
            LC_COLLATE = "C"
            LC_CTYPE = "C";
        '';
      };

      nginx.virtualHosts."${address}" = {
        locations."/".proxyPass = "http://${config.constants.loopbackAddr}:${toString clientPort}";
        useACMEHost = baseDomain;
        forceSSL = true;
        kTLS = true;
      };
    };

    security.acme.certs."${baseDomain}".postRun = "systemctl restart matrix-synapse.service";

    system.activationScripts.synapse-dir-creation.text = "install -o matrix-synapse -g matrix-synapse -d ${config.services.matrix-synapse.dataDir}";

    # TODO: remove me: needed by heisenbridge
    nixpkgs.config.permittedInsecurePackages = [ "olm-3.2.16" ];
  };
}
