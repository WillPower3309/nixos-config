{ inputs, ... }:

{
  flake.modules.nixos.wifi = { config, ... }: {
    networking.networkmanager = {
      enable = true;
      wifi.macAddress = "random";
    };

    environment.persistence."${config.constants.persistentDir}".directories = [ "/etc/NetworkManager/system-connections" ];
  };
}
