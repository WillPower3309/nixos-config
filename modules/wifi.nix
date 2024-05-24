{ config, pkg, ... }:

{
  networking.networkmanager = {
    enable = true;
    wifi.macAddress = "random";
    dns = "systemd-resolved";
  };

  environment.persistence."/nix/persist".directories = [
    "/etc/NetworkManager/system-connections"
  ];
}
