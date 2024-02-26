{ pkgs, ... }:

{
  services.transmission = {
    enable = true;
    openRPCPort = true;
    settings = {
      download-dir = "/persist/transmission/download"; # TODO
      incomplete-dir = "/persist/transmission/incomplete"; # TODO
      rpc-bind-address = "0.0.0.0";
      rpc-whitelist = "127.0.0.1,10.27.27.5,192.168.100.*"; # allow desktop and nebula devices to connect
    };
  };
}

