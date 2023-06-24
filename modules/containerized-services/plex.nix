{ config, ... }:

let
  plex-media-dir = "/data/plex";
  plex-claim-token = "";
in
{
  virtualisation.oci-containers.containers = {
    plex = {
      image = "plexinc/pms-docker";

      volumes = [
        "${plex-media-dir}/database:/config"
        "${plex-media-dir}/transcode:/transcode"
        "${plex-media-dir}/media:/data"
      ];

      environment = {
        TZ = "America/Toronto";
        PLEX_CLAIM = "${plex-claim-token}";
      };

      extraOptions = [ "--network=host" ];
    };
  };

  networking.firewall = {
    allowedTCPPorts = [ 32400 8324 32469 ];
    allowedUDPPorts = [ 1900 32410 32412 32413 32414 ];
  };
}
