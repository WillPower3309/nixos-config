{ pkgs, ... }:

# TODO: add server as introducer
# TODO: add check for cert and key
# TODO: remove webgui?
{
  services.syncthing = {
    enable = true;
    dataDir = "/syncthing";
    openDefaultPorts = true;
    overrideDevices = true; # overrides any devices added or deleted through the WebUI
    overrideFolders = true; # overrides any folders added or deleted through the WebUI
    guiAddress = "0.0.0.0:8384";
    settings = {
      options.urAccepted = -1;

      devices.server = {
        id = "V5AV6D5-5ITLYTL-35UHX6S-LKMFZ6U-FVGLEZP-EFGGR3R-O6AVGG7-ONT5MQE";
        autoAcceptFolders = true;
      };
    };
  };
  networking.firewall.allowedTCPPorts = [ 8384 ];
}
