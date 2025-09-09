{ config, lib, ... }:

with config.networking;

let lighthouseNebulaAddress = "192.168.100.1";

in
{
  age.secrets = {
    nebulaCaCert = {
      file = ../secrets/nebulaCaCert.age;
      owner = "nebula-home";
      group = "nebula-home";
    };
    nebulaDeviceCert = {
      file = ./.. + builtins.toPath "/secrets/${hostName}NebulaCert.age";
      owner = "nebula-home";
      group = "nebula-home";
    };
    nebulaDeviceKey = {
      file = ./.. + builtins.toPath "/secrets/${hostName}NebulaKey.age";
      owner = "nebula-home";
      group = "nebula-home";
    };
  };

  # lighthouse: 192.168.100.1
  # server: 192.168.100.2
  # desktop: 192.168.100.3
  # laptop: 192.168.100.4
  # phone: 192.168.100.5
  # pikvm: 192.168.100.6
  services.nebula.networks.home = {
    enable = true;
    isLighthouse = false;
    cert = config.age.secrets.nebulaDeviceCert.path; # <device>.crt
    key = config.age.secrets.nebulaDeviceKey.path; # <device>.key
    ca = config.age.secrets.nebulaCaCert.path; # ca.crt
    lighthouses = [ lighthouseNebulaAddress ];
    staticHostMap = { ${lighthouseNebulaAddress} = [ "lighthouse.willmckinnon.com:4242" ]; };
    listen.port = if hostName == "server" then 4242 else 0; # TODO: fix me so server can have value of 0
    settings = {
      punchy = {
        punch = true;
        respond = true;
        delay = "1s";
        respond_delay = "5s";
      };
      preferred_ranges = [ "10.27.27.0/24" ]; # prefer local network
      pki.disconnect_invalid = true; # close tunnels to hosts which are no longer trusted
    };
    firewall = {
      inbound = lib.lists.forEach firewall.allowedTCPPorts (port: {
        port = port;
        proto = "tcp";
        host = "any";
      }) ++ lib.lists.forEach firewall.allowedUDPPorts (port: {
        port = port;
        proto = "udp";
        host = "any";
      });
      outbound = [{
        port = "any";
        proto = "any";
        host = "any";
      }];
    };
  };
}

