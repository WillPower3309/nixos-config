{ config, pkgs, ... }:

let
  baseDomain = "${config.networking.hostName}.willmckinnon.com";
  address = "transmission.${baseDomain}";
  wgNamespace = "wg";
  wgInterface = "wg0";

in {
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
  systemd.services = {
    transmission = {
      after = [ "wireguard-${wgInterface}.service" ];
      serviceConfig.NetworkNamespacePath = "/var/run/netns/${wgNamespace}";
    };

    # TODO: systemd socket based approach https://www.man7.org/linux/man-pages/man8/systemd-socket-proxyd.8.html
    transmission-namespace-forward = {
      after = [ "wireguard-${wgInterface}.service" "transmission.service" ];
      wantedBy = [ "transmission.service" ];
      serviceConfig = {
        Restart = "on-failure";
        ExecStart = let
          socatBin = "${pkgs.socat}/bin/socat";
          transmissionAddress = config.services.transmission.settings.rpc-bind-address;
          transmissionPort = toString config.services.transmission.settings.rpc-port;
        in ''
          ${socatBin} tcp-listen:${transmissionPort},fork,reuseaddr \
            exec:'${pkgs.iproute2}/bin/ip netns exec ${wgNamespace} ${socatBin} STDIO "tcp-connect:${transmissionAddress}:${transmissionPort}"',nofork
        '';
      };
    };
  };

  age.secrets = {
    wireguardPrivateKey.file = ./.. + builtins.toPath "/secrets/${config.networking.hostName}WireguardPrivateKey.age";
    wireguardPeerPresharedKey.file = ./.. + builtins.toPath "/secrets/${config.networking.hostName}WireguardPeerPresharedKey.age";
  };

  networking.wireguard.interfaces.${wgInterface} = {
    ips = [ "10.149.207.226/32" ];
    privateKeyFile = config.age.secrets.wireguardPrivateKey.path;
    interfaceNamespace = wgNamespace;
    mtu = 1320;
    peers = [{
      endpoint = "america3.vpn.airdns.org:1637";
      publicKey = "PyLCXAQT8KkM4T+dUsOQfn+Ub3pGxfGlxkIApuig+hk=";
      presharedKeyFile = config.age.secrets.wireguardPeerPresharedKey.path;
      allowedIPs = [ "0.0.0.0/0" "::/0" ];
      persistentKeepalive = 15;
    }];
    preSetup = [ "${pkgs.iproute2}/bin/ip netns add ${wgNamespace} || true" ];
#    postSetup = [ "${pkgs.iproute2}/bin/ip -n ${wgNamespace} link set lo up" ];
    postShutdown = [ "${pkgs.iproute2}/bin/ip netns del ${wgNamespace}" ];
  };
}

