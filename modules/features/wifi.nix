{ inputs, ... }:

{
  flake.modules.nixos.wifi = { config, ... }: {
    networking.networkmanager = {
      enable = true;
      wifi.macAddress = "random";
    };

    #regulatory database that tells the WiFi card which frequencies and power levels are legal per country
    hardware.wirelessRegulatoryDatabase = true;

    environment.persistence."${config.constants.persistentDir}".directories = [ "/etc/NetworkManager/system-connections" ];
  };
}
