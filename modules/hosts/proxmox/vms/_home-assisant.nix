# TODO: should this run in a proxmox container instead?
# TODO: or should this run via the HA ISO? Could pass a volume for config
{ config, ... }:

let
  configDir = "${config.constants.persistentDir}/home-assistant";

in {
  networking.hostName = "home-assistant";

  virtualisation = {
    proxmox = {
      node = "pve0"; # TODO: do I have to?
      autoInstall = true;
      vmid = 101; # TODO: set this dynamically? Is this required?
      memory = 1024;
      cores = 1;
      sockets = 1;
    };

    # run in a container since it is sadly not recommended to run the nixos version of HA
    virtualisation.oci-containers = {
      backend = "podman";
      containers = {
        home-assistant = {
          image = "ghcr.io/home-assistant/home-assistant:stable";
          volumes = [
            "${configDir}:/config"
            "/etc/localtime:/etc/localtime:ro"
            "/run/dbus:/run/dbus:ro"
          ];
          environment.TZ = config.time.timeZone;
          extraOptions = [ "--network=host" ]; # Use the host network namespace for all sockets
        };
      };
    };
  };

  environment.persistence."${config.constants.persistentDir}" = {
    hideMounts = true;
    directories = [
      "/var/log"
      "/var/lib/nixos"
    ];
  };

  networking.firewall.allowedTCPPorts = [ 8123 ];
}

