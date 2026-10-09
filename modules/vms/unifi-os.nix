{ inputs, ... }:

let
  hostName = "unifi-os";
  macAddress = "02:00:00:00:00:02";
  ipAddress = "10.1.10.12";
  persistentDir = "/persist";

in {
  flake.microvms.${hostName} = {
    vfs = [{ mac = macAddress; vlan = 10; }];
    proxy.unifi = {
      port = 11443; # services.unifi-os-server.ports.ui
      scheme = "https";
    };
  };

  flake.networks."10".reservations = [{
    ip-address = ipAddress;
    hostname = hostName;
    hw-address = macAddress;
  }];

  flake.modules.nixos.${hostName} = {
    imports = [
      ./_common.nix
      inputs.microvm.nixosModules.microvm
      inputs.unifi-os-server.nixosModules.unifi-os-server
    ];

    networking = { inherit hostName; };

    microvm = {
      vcpu = 1;
      mem = 3072;
      # TODO: Move to seaweedfs
      volumes = [
        {
          # the image unpacks to ~1.9GB, and an upgrade holds the old and new images until the old one is pruned
          image = "var-lib-containers.img";
          mountPoint = "/var/lib/containers";
          size = 5120;
        }
        {
          image = "persist.img";
          mountPoint = persistentDir;
          size = 3072;
        }
      ];
    };

    virtualisation = {
      oci-containers.backend = "podman";
      podman.autoPrune = {
        enable = true;
        flags = [ "--all" ]; # also remove old (tagged but unused) unifi-os-server images
      };
    };
    # updates restart the VM, so also prune once the new image is loaded and in use
    systemd.services.podman-prune = {
      wantedBy = [ "multi-user.target" ];
      after = [ "podman-unifi-os-server.service" ];
    };

    services.unifi-os-server = {
      enable = true;
      stateDir = persistentDir;
      uosSystemIP = ipAddress; # devices adopt via http://<ip>:8080/inform
      openFirewallUiPort = true;
      openFirewallServicePorts = true;
    };
  };
}
