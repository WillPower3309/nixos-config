{ config, ... }:

with config.networking;

{
  age.secrets = {
    nebulaCaCert = {
      file = ../../secrets/nebulaCaCert.age;
      owner = "nebula-home";
      group = "nebula-home";
    };
    nebulaDeviceCert = {
      file = ../.. + builtins.toPath "/secrets/nebula${hostName}Cert.age";
      owner = "nebula-home";
      group = "nebula-home";
    };
    nebulaDeviceKey = {
      file = ../.. + builtins.toPath "/secrets/nebula${hostName}Key.age";
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
    staticHostMap = { "192.168.100.1" = [ "143.110.232.34:4242" ]; };
    settings = {
      punchy = true;
      punch_back = true;
    };
    firewall = {
      inbound = [{
        host = "any";
        port = "any";
        proto = "any";
      }];
      outbound = [{
        host = "any";
        port = "any";
        proto = "any";
      }];
    };
  };
}
