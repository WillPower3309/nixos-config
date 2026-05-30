{ inputs, ... }:
{
  flake.modules.nixos.nebula = { config, lib, ... }: {
    imports = [ inputs.agenix.nixosModules.age ];

    age.secrets = {
      nebulaCaCert = {
        file = ./nebulaCaCert.age;
        owner = "nebula-home";
        group = "nebula-home";
      };
      nebulaDeviceCert = {
        file = ./${config.networking.hostName}NebulaCert.age;
        owner = "nebula-home";
        group = "nebula-home";
      };
      nebulaDeviceKey = {
        file = ./${config.networking.hostName}NebulaKey.age;
        owner = "nebula-home";
        group = "nebula-home";
      };
    };

    # lighthouse: 192.168.100.1
    # pve0: 192.168.100.2
    # pve1: 192.168.100.3
    # pve2: 192.168.100.4
    # desktop: 192.168.100.5
    # laptop: 192.168.100.6
    # phone: 192.168.100.7
    # pinenote: 192.168.100.8
    # server: 192.168.100.9
    services.nebula.networks.home = let lighthouseNebulaAddress = "192.168.100.1"; in {
      enable = true;
      isLighthouse = false;
      cert = config.age.secrets.nebulaDeviceCert.path; # <device>.crt
      key = config.age.secrets.nebulaDeviceKey.path; # <device>.key
      ca = config.age.secrets.nebulaCaCert.path; # ca.crt
      lighthouses = [ lighthouseNebulaAddress ];
      relays = [ lighthouseNebulaAddress ];
      staticHostMap = { ${lighthouseNebulaAddress} = [ "lighthouse.willmckinnon.com:4242" ]; }; # TODO: dynamic from lighthouse conf
      listen.port = if config.networking.hostName == "server" then 4242 else 0; # TODO: fix me so server can have value of 0
      settings = {
        punchy = {
          punch = true;
          respond = true;
          delay = "1s";
          respond_delay = "5s";
        };
        preferred_ranges = [ "192.168.100.0/24" ]; # prefer nebula network since split brain DNS is set up
        pki.disconnect_invalid = true; # close tunnels to hosts which are no longer trusted
      };
      firewall = {
        inbound = lib.lists.forEach config.networking.firewall.allowedTCPPorts (port: {
          port = port;
          proto = "tcp";
          host = "any";
        }) ++ lib.lists.forEach config.networking.firewall.allowedUDPPorts (port: {
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
  };
}

