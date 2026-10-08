{ inputs, ... }:

let
  hostName = "home-assistant";
  macAddress = "02:00:00:00:00:01";

in {
  flake.microvms.${hostName} = { };

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
      interfaces.eth0 = { inherit macAddress; };
      firewall.allowedTCPPorts = [ 8123 ];
    };

    microvm = {
      vcpu = 1;
      mem = 4096;
      # TODO: Move to seaweedfs
      volumes = [{
        image = "var-lib-containers.img"; # relative to the nomad job's workDir, /var/lib/microvms/home-assistant (persisted)
        mountPoint = "/var/lib/containers"; # image is too big to store in microvm memory
        size = 8192;
      }];
    };

    virtualisation.oci-containers = {
      backend = "podman";
      containers.homeassistant = {
        environment.TZ = config.time.timeZone;
        # Note: The image will not be updated on rebuilds, unless the version label changes
        image = "ghcr.io/home-assistant/home-assistant:stable";
        extraOptions = [ "--network=host" ];
      };
    };
  };
}
