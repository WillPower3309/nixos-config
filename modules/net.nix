{ config, pkg, ... }:

{
  networking.hostName = "desktop";

  networking.networkmanager = {
    enable = true;
    wifi.macAddress = "random";
    ethernet.macAddress = "random";
  };
}
