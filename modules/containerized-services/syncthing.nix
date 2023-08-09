{ config, ... }:

{
  virtualisation.oci-containers.containers = {
    syncthing = {
      image = "syncthing/syncthing";
      volumes = [ "/data/syncthing:/var/syncthing" ];
      extraOptions = [ "--network=host" ];
      environment = {
        PUID = "1000";
        PGID = "1000";
      };
      ports = [
        "8384:8384"
        "22000:22000/tcp"
        "22000:22000/udp"
        "21027:21027/udp"
      ];
    };
  };

  networking.firewall = {
    allowedTCPPorts = [
      8384 # Web UI
      22000 # TCP file transfers
    ];
    allowedUDPPorts = [
      22000 # QUIC file transfers
      21027 # Receive local discovery broadcasts
    ];
  };
}
