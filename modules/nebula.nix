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
  # phone: 192.168.100.4
  services.nebula.networks.home = {
    enable = true;
    isLighthouse = false;
    cert = config.age.secrets.nebulaDeviceCert.path; # <device>.crt
    key = config.age.secrets.nebulaDeviceKey.path; # <device>.key
    ca = config.age.secrets.nebulaCaCert.path; # ca.crt
    lighthouses = [ lighthouseNebulaAddress ];
    relays = [ lighthouseNebulaAddress ];
    staticHostMap = { ${lighthouseNebulaAddress} = [ "143.110.232.34:4242" ]; };
    listen.port = if hostName == "server" then 4242 else 0; # TODO: fix me so server can have value of 0
    settings = {
      punchy = {
        punch = true;
        respond = true;
        delay = "1s";
        respond_delay = "5s";
      };
      preferred_ranges = [ "10.27.27.0/24" ]; # prefer local network
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

