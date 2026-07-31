{ inputs, ... }:

let name = "home-assistant"; port = 8123; in {
  flake.packages.x86_64-linux."${name}-vm" = inputs.self.lib.mkMicrovmPackage "x86_64-linux" name;

  flake.modules.nixos.${name} = { config, ... }: {
    imports = [ inputs.microvm.nixosModules.microvm ];

    microvm = {
      hypervisor = "qemu";
      vcpu = 1;
      mem = 4096;
      interfaces = [{
        type = "user";
        id = "ha";
        mac = "02:00:00:00:00:01";
      }];
      # TODO: Move to seaweedfs
      volumes = [{
        image = "var-lib-containers.img"; # TODO: where is this on the hypervisor?
        mountPoint = "/var/lib/containers"; # image is too big to store in microvm memory
        size = 8192;
      }];
      # TODO: https://microvm-nix.github.io/microvm.nix/shares.html#writable-nixstore-overlay
      shares = [{
        tag = "ro-store";
        source = "/nix/store";
        mountPoint = "/nix/.ro-store";
      }];
      forwardPorts = [{
        from = "host";
        host = { inherit port; };
        guest = { inherit port; };
      }];
    };

    services.getty.autologinUser = "root";

    system.stateVersion = config.system.nixos.release;
    time.timeZone = "America/Toronto";

    virtualisation.oci-containers = {
      backend = "podman";
      containers.homeassistant = {
        environment.TZ = config.time.timeZone;
        image = "ghcr.io/home-assistant/home-assistant:stable"; # Note: The image will not be updated on rebuilds, unless the version label changes
        extraOptions = [ "--network=host" ];
      };
    };

    networking.firewall.allowedTCPPorts = [ port ];
  };
}
