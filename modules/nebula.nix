{ config, lib, ... }:

with config.networking;

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

  # TODO: preferred_ranges: https://nebula.defined.net/docs/config/preferred-ranges/
  services.nebula.networks.home = {
    enable = true;
    isLighthouse = false;
    cert = config.age.secrets.nebulaDeviceCert.path; # <device>.crt
    key = config.age.secrets.nebulaDeviceKey.path; # <device>.key
    ca = config.age.secrets.nebulaCaCert.path; # ca.crt
    lighthouses = [ "192.168.100.1" ];
    relays = [ "192.168.100.1" ];
    staticHostMap = { "192.168.100.1" = [ "143.110.232.34:4242" ]; };
    # listen.port = 0; # TODO: set port to 0 for laptop? I THINK THIS IS BROKEN ON NIX
    settings = {
      punchy = {
        punch = true;
        respond = true;
        delay = "1s";
        respond_delay = "5s";
      };
    };
    firewall = {
      inbound = lib.lists.forEach firewall.allowedTCPPorts (port: {
        host = "any";
        port = port;
        proto = "tcp";
      }) ++ lib.lists.forEach firewall.allowedUDPPorts (port: {
        host = "any";
        port = port;
        proto = "udp";
      });
      outbound = [{
        host = "any";
        port = "any";
        proto = "any";
      }];
    };
  };
}

