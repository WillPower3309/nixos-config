{ inputs, ... }:

{
  flake.modules.nixos.wifi = {
    networking.networkmanager = {
      enable = true;
      wifi.macAddress = "random";
    };

    environment.persistence."/nix/persist".directories = [ "/etc/NetworkManager/system-connections" ];
  };
}
