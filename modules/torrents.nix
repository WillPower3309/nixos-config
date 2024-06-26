{ config, pkgs, ... }:

let
  baseDomain = "${config.networking.hostName}.willmckinnon.com";
  address = "transmission.${baseDomain}";
  wgNamespace = "wg";

in
{
  services = {
    transmission = {
      enable = true;
      settings = {
        download-dir = "/persist/transmission/download"; # TODO
        incomplete-dir = "/persist/transmission/incomplete"; # TODO
        rpc-bind-address = "127.0.0.1";
        rpc-url = "/transmission/";
        rpc-host-whitelist-enabled = true;
        rpc-host-whitelist = address;
      };
    };

    nginx.virtualHosts."${address}" = {
      useACMEHost = baseDomain;
      forceSSL = true;
      kTLS = true;
      locations = {
        "/".return = "301 http://${address}/transmission/web/";

        "${config.services.transmission.settings.rpc-url}" = {
          proxyPass = "http://${config.services.transmission.settings.rpc-bind-address}:${toString config.services.transmission.settings.rpc-port}";
          extraConfig = ''
            proxy_read_timeout 300;
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Forwarded-Protocol $scheme;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-Host $host;
            proxy_set_header X-Forwarded-Server $host;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_pass_header X-Transmission-Session-Id;
          '';
        };
      };

      # allow iframe
      extraConfig = ''
        proxy_hide_header X-Frame-Options;
      '';
    };
  };

  # add transmission to the wireguard network namespace
  systemd.services.transmission = {
    requires = [ "wireguard-wg0.service" ];
    serviceConfig.NetworkNamespacePath = "/var/run/netns/${wgNamespace}";
  };

  age.secrets.wireguardPrivateKey.file = ./.. + builtins.toPath "/secrets/${config.networking.hostName}WireguardPrivateKey.age";

  networking.wireguard.interfaces = {
    wg0 = {
      ips = [ "10.0.0.1/32" ];
      privateKeyFile = config.age.secrets.wireguardPrivateKey.path;
      interfaceNamespace = wgNamespace;
      peers = [{
        endpoint = "se-got-wg-001.relays.mullvad.net:51820";
        publicKey = "5JMPeO7gXIbR5CnUa/NPNK4L5GqUnreF0/Bozai4pl4=";
        persistentKeepalive = 15;
        # Forward all traffic via VPN.
        allowedIPs = [ "0.0.0.0/0" "::/0" ];
      }];

      # TODO:
      #${pkgs.socat}/bin/socat tcp-listen:${toString config.services.transmission.settings.rpc-port},fork,reuseaddr exec:'${pkgs.iproute2}/bin/ip netns exec ${wgNamespace} ${pkgs.socat}/bin/socat STDIO "tcp-connect:${config.services.transmission.settings.rpc-bind-address}:${toString config.services.transmission.settings.rpc-port}"',nofork
      preSetup = ''
        ${pkgs.iproute2}/bin/ip netns add ${wgNamespace} || true
        ${pkgs.iproute2}/bin/ip netns exec ${wgNamespace} ${pkgs.nettools}/bin/ifconfig lo up
      '';
      postShutdown = [ "${pkgs.iproute2}/bin/ip netns del ${wgNamespace}" ];
    };
  };
}

