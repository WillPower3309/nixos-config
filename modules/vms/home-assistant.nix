{ inputs, ... }:

let name = "home-assistant"; in {
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
      # TODO: https://microvm-nix.github.io/microvm.nix/shares.html#writable-nixstore-overlay
      shares = [{
        tag = "ro-store";
        source = "/nix/store";
        mountPoint = "/nix/.ro-store";
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
  };
}
