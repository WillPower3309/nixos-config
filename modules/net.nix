{ config, pkg, ... }:

{
  networking.hostName = "surface";

  networking.networkmanager = {
    enable = true;
    wifi.macAddress = "random";
    ethernet.macAddress = "random";
  };
}
