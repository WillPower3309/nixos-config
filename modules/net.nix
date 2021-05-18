{ config, pkg, ... }:

{
  networking.hostName = "farnsworth";

  networking.networkmanager = {
    enable = true;
    wifi.macAddress = "random";
    ethernet.macAddress = "random";
  };
}
