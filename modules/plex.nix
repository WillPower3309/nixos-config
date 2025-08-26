{ config, lib, pkgs, ... }:

let
  plexPort = 32400;
  localAddress = "127.0.0.1:${toString plexPort}";
  baseDomain = "${config.networking.hostName}.willmckinnon.com";
  address = "plex.${baseDomain}";

in
{
  services = {
    plex = {
      enable = true;
      dataDir = "/data/plex";
      openFirewall = false; # we don't need the web gui port 32400 exposed thanks to nginx
    };

    # https://toxicfrog.github.io/reverse-proxying-plex-with-nginx-on-nixos/
    nginx.virtualHosts."${address}" = {
      useACMEHost = baseDomain;
      forceSSL = true;
      kTLS = true;
      locations."/".proxyPass = "http://${localAddress}";

      # add config to:
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

    autossh.sessions = [{
      # TODO: don't use root user, use diff key?
      # TODO: have ~/.ssh/known_hosts generated for the tunnel remote, and remove `-o StrictHostKeyChecking=no`
      extraArguments = "-N -R ${toString plexPort}:localhost:${toString plexPort} -o StrictHostKeyChecking=no root@159.203.59.54 -i /persist/etc/ssh/ssh_host_ed25519_key";
      name = "plex-tunnel";
      user = "root"; # TODO: use a new user when this module is fixed: https://github.com/NixOS/nixpkgs/issues/373024
    }];
  };

  networking.firewall = {
    allowedTCPPorts = [ 3005 8324 32469 plexPort ];
    allowedUDPPorts = [ 1900 5353 32410 32412 32413 32414 ];
  };
}
