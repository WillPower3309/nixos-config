{ config, ... }:

{
  time.timeZone = "America/Toronto";
  services.getty.autologinUser = "root";
  system.stateVersion = config.system.nixos.release;

  microvm = {
    hypervisor = "qemu";
    interfaces = [{
      type = "user";
      id = "veth0";
      mac = "02:00:00:00:00:01";
    }];
    # TODO: https://microvm-nix.github.io/microvm.nix/shares.html#writable-nixstore-overlay
    shares = [{
      tag = "ro-store";
      source = "/nix/store";
      mountPoint = "/nix/.ro-store";
    }];
    # TODO: ranges
    forwardPorts = let genPortForward = port: proto: {
      from = "host";
      inherit proto;
      host = { inherit port; };
      guest = { inherit port; };
    }; in map(port: genPortForward port "tcp") config.networking.firewall.allowedTCPPorts
      ++ map(port: genPortForward port "udp") config.networking.firewall.allowedUDPPorts;
  };
}
