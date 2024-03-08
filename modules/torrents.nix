{ config, pkgs, ... }:

let
  address = "transmission.${config.networking.hostName}.willmckinnon.com";

in
{
  services = {
    transmission = {
      enable = true;
      openRPCPort = true;
      settings = {
        download-dir = "/persist/transmission/download"; # TODO
        incomplete-dir = "/persist/transmission/incomplete"; # TODO
        rpc-bind-address = "127.0.0.1";
        rpc-url = "/transmission/";
        rpc-host-whitelist-enabled = true;
        rpc-host-whitelist = address;
      };
    };

    # TODO: fix me
    nginx.virtualHosts."${address}" = {
#      useACMEHost = address;
#      forceSSL = true;
#      kTLS = true;
      locations."${config.services.transmission.settings.rpc-url}" = {
        proxyPass = "http://${config.services.transmission.settings.rpc-bind-address}:${toString config.services.transmission.settings.rpc-port}";
        extraConfig = ''
          proxy_read_timeout 300;
          proxy_set_header Host $host;
          proxy_set_header X-Forwarded-Proto $scheme;
          proxy_set_header X-Forwarded-Protocol $scheme;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_pass_header X-Transmission-Session-Id;
          proxy_set_header X-Forwarded-Host $host;
          proxy_set_header X-Forwarded-Server $host;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        '';
      };

      # allow iframe
      extraConfig = ''
        proxy_hide_header X-Frame-Options;
      '';
    };
  };

#  security.acme.certs."${address}" = {};
}

