{ inputs, ... }:

{
  flake.modules.nixos.plex = { config, lib, pkgs, ... }: let
    plexPort = 32400;
    localAddress = "${config.constants.loopbackAddr}:${toString plexPort}";
    baseDomain = config.networking.fqdn;
    address = "plex.${baseDomain}";

  in {
    services = {
      plex = {
        enable = true;
        dataDir = "/data/plex";
        openFirewall = true;
      };

      nginx.virtualHosts."${address}" = {
        useACMEHost = baseDomain;
        forceSSL = true;
        kTLS = true;
        locations."/".proxyPass = "http://${localAddress}";

        # 1. clears the headers that plex uses to determine remote access
        # 2. enables proxying of websockets
        # 3. turns off buffering to reduce latency when watching video
        extraConfig = ''
          proxy_set_header Host "${localAddress}";
          proxy_set_header Referer "";
          proxy_set_header Origin "http://${localAddress}";

          proxy_set_header Sec-WebSocket-Extensions $http_sec_websocket_extensions;
          proxy_set_header Sec-WebSocket-Key $http_sec_websocket_key;
          proxy_set_header Sec-WebSocket-Version $http_sec_websocket_version;
          proxy_http_version 1.1;
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection "Upgrade";

          proxy_redirect off;
          proxy_buffering off;
        '';
      };

      # TODO: don't use root user, use diff key?
      # TODO: have ~/.ssh/known_hosts generated for the tunnel remote, and remove `-o StrictHostKeyChecking=no`
      autossh.sessions = [{
        extraArguments = "-nNT -o ServerAliveInterval=10 -o ServerAliveCountMax=2 -R ${toString plexPort}:localhost:${toString plexPort} -o StrictHostKeyChecking=no root@lighthouse.willmckinnon.com -i ${config.constants.persistentDir}/etc/ssh/ssh_host_ed25519_key -p 2222";
        name = "plex-tunnel";
        user = "root";
      }];
    };
  };
}
