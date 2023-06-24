{ config, ... }:

{
  virtualisation.oci-containers.containers = {
    syncthing = {
      image = "syncthing/syncthing";
      volumes = [ "/data/syncthing:/var/syncthing" ];
      extraOptions = [ "--network=host" ];
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

