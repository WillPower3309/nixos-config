{ inputs, ... }:

{
  flake.modules.nixos.torrents = { config, lib, pkgs, ... }: let
    baseDomain = config.networking.fqdn;
    address = "transmission.${baseDomain}";
    wgNamespace = "wg";
    wgInterface = "wg0";
    wgDns = "10.128.0.1";
    wgIp = "10.180.78.240/32";
    wgEndpoint = "america3.vpn.airdns.org:1637";
    wgPublicKey = "PyLCXAQT8KkM4T+dUsOQfn+Ub3pGxfGlxkIApuig+hk=";

  in {
    services = {
      transmission = {
        enable = true;
        openPeerPorts = true; # TODO: on wireguard interface

        settings = {
          download-dir = "${config.constants.persistentDir}/transmission/download"; # TODO
          incomplete-dir = "${config.constants.persistentDir}/transmission/incomplete"; # TODO
          rpc-bind-address = config.constants.loopbackAddr;
          rpc-url = "/transmission/";
          rpc-host-whitelist-enabled = true;
          rpc-host-whitelist = address;

          peer-port = 39894;

          # auto extract rar
          script-torrent-done-enabled = true;
          script-torrent-done-filename = pkgs.writeText "extract.sh" ''
            #!/bin/bash
            find /$TR_TORRENT_DIR/$TR_TORRENT_NAME -name "*.rar" -execdir ${pkgs.unrar}/bin/unrar e -o- "{}" \;
          '';
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
            transmissionRPCPort = toString config.services.transmission.settings.rpc-port;
          in ''
            ${socatBin} tcp-listen:${transmissionRPCPort},fork,reuseaddr \
              exec:'${pkgs.iproute2}/bin/ip netns exec ${wgNamespace} ${socatBin} STDIO "tcp-connect:${transmissionAddress}:${transmissionRPCPort}"',nofork
          '';
        };
      };
    };

    age.secrets = {
      wireguardPrivateKey.file = ./${config.networking.hostName}WireguardPrivateKey.age;
      wireguardPeerPresharedKey.file = ./${config.networking.hostName}WireguardPeerPresharedKey.age;
    };

    # TODO: do the below in networkd?
    networking.useNetworkd = lib.mkForce false;
    networking.wireguard.interfaces.${wgInterface} = {
      ips = [ wgIp ];
      privateKeyFile = config.age.secrets.wireguardPrivateKey.path;
      interfaceNamespace = wgNamespace;
      mtu = 1320;
      peers = [{
        endpoint = wgEndpoint;
        publicKey = wgPublicKey;
        presharedKeyFile = config.age.secrets.wireguardPeerPresharedKey.path;
        allowedIPs = [ "0.0.0.0/0" "::/0" ];
        persistentKeepalive = 15;
      }];
      preSetup = [ "${pkgs.iproute2}/bin/ip netns add ${wgNamespace} || true" ];
      postSetup = [ "${pkgs.iproute2}/bin/ip -n ${wgNamespace} link set lo up" ];
      postShutdown = [ "${pkgs.iproute2}/bin/ip netns del ${wgNamespace}" ];
    };

    environment.etc."netns/${wgNamespace}/resolv.conf".text = ''
      nameserver ${wgDns}
      options edns0 trust-ad ndots:0
    '';
  };
}
