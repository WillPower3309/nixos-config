{ inputs, ... }:

let name = "home-assistant"; in {
  flake.packages.x86_64-linux."${name}-vm" = inputs.self.lib.mkMicrovmPackage "x86_64-linux" name;

  flake.modules.nixos.${name} = { config, ... }: {
    imports = [ ./_common.nix inputs.microvm.nixosModules.microvm ];

    microvm = {
      vcpu = 1;
      mem = 4096;
      # TODO: Move to seaweedfs
      volumes = [{
        image = "var-lib-containers.img"; # TODO: where is this on the hypervisor?
        mountPoint = "/var/lib/containers"; # image is too big to store in microvm memory
        size = 8192;
      }];
    };

    virtualisation.oci-containers = {
      backend = "podman";
      containers.homeassistant = {
        environment.TZ = config.time.timeZone;
        image = "ghcr.io/home-assistant/home-assistant:stable"; # Note: The image will not be updated on rebuilds, unless the version label changes
        extraOptions = [ "--network=host" ];
      };
    };

    networking.firewall.allowedTCPPorts = [ 8123 ];
  };
}
