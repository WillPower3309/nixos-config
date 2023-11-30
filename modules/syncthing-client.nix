{ pkgs, ... }:

# TODO: add check for cert and key
# TODO: remove webgui?
{
  services.syncthing = {
    enable = true;
    dataDir = "/home/will";
    configDir = "/etc/syncthing";
    user = "will";
    openDefaultPorts = true;
    overrideDevices = false; # need this for introducer
    overrideFolders = false; # need this for autoAcceptFolders
    guiAddress = "0.0.0.0:8384";
    settings = {
      options.urAccepted = -1;

      devices.server = {
        id = "V5AV6D5-5ITLYTL-35UHX6S-LKMFZ6U-FVGLEZP-EFGGR3R-O6AVGG7-ONT5MQE";
        autoAcceptFolders = true;
        introducer = true;
      };
    };
  };
  networking.firewall.allowedTCPPorts = [ 8384 ];
}
