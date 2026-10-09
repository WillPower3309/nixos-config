{ inputs, ... }:

let
  hostName = "home-assistant";
  macAddress = "02:00:00:00:00:01";
  persistentDir = "/persist";
  uiPort = 8123;

in {
  flake.microvms.${hostName} = {
    vfs = [{ mac = macAddress; vlan = 10; }];
    proxy.ha.port = uiPort;
  };

  flake.networks."10".reservations = [{
    ip-address = "10.1.10.11";
    hostname = hostName;
    hw-address = macAddress;
  }];

  flake.modules.nixos.${hostName} = { config, ... }: {
    imports = [
      ./_common.nix
      inputs.microvm.nixosModules.microvm
    ];

    networking = {
      inherit hostName;
      firewall.allowedTCPPorts = [ uiPort ];
    };

    microvm = {
      vcpu = 1;
      mem = 4096;
      # TODO: Move to seaweedfs
      volumes = [
        {
          image = "var-lib-containers.img";
          mountPoint = "/var/lib/containers";
          size = 8192;
        }
        {
          image = "persist.img";
          mountPoint = persistentDir;
          size = 64;
        }
      ];
    };

    virtualisation.oci-containers = {
      backend = "podman";
      containers.homeassistant = {
        environment.TZ = config.time.timeZone;
        # Note: The image will not be updated on rebuilds, unless the version label changes
        image = "ghcr.io/home-assistant/home-assistant:stable";
        extraOptions = [ "--network=host" ];
        volumes = [ "${persistentDir}:/config" ];
      };
    };
  };
}
