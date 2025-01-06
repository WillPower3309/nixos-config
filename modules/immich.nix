{ config, ... }:

let
  loopbackIp = "127.0.0.1";
  baseDomain = "${config.networking.hostName}.willmckinnon.com";

in {
  imports = [ ./postgresql.nix ];

  services = {
    immich = {
      enable = true;
      mediaLocation = "/data/immich";
      host = "0.0.0.0";
      machine-learning.enable = false;
    };

    nginx.virtualHosts."immich.${baseDomain}" = {
      useACMEHost = baseDomain;
      forceSSL = true;
      kTLS = true;
      locations."/".proxyPass = "http://${loopbackIp}:${toString config.services.immich.port}";

      extraConfig = ''
        # allow large file uploads
        client_max_body_size 50000M;

        # Set headers
        proxy_set_header Host "${loopbackIp}";
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # enable websockets: http://nginx.org/en/docs/http/websocket.html
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_redirect off;

        # set timeout
        proxy_read_timeout 600s;
        proxy_send_timeout 600s;
        send_timeout       600s;
      '';
    };
  };

  system.activationScripts.immich-dir-creation.text = "install -o ${config.services.immich.user} -g ${config.services.immich.group} -d ${config.services.immich.mediaLocation}";
}

