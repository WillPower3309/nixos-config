{ lib, ... }:

let
  reservationType = lib.types.submodule {
    options = {
      ip-address = lib.mkOption { type = lib.types.str; };
      hostname = lib.mkOption { type = lib.types.str; };
      hw-address = lib.mkOption { type = lib.types.str; };
    };
  };

  networkType = lib.types.submodule {
    options = {
      id = lib.mkOption { type = lib.types.int; };
      internet = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      dns = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      routerSsh = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      reservations = lib.mkOption {
        type = lib.types.listOf reservationType;
        default = [];
      };
    };
  };
in {
  options.flake.networks = lib.mkOption {
    type = lib.types.lazyAttrsOf networkType;
  };

  config.flake.networks = {
    trusted = {
      id = 10;
      internet = true;
      routerSsh = true;
      dns = true;
      reservations = [
        { ip-address = "10.1.10.5"; hw-address = "f8:27:2e:0c:02:ef"; hostname = "access-point"; }
        { ip-address = "10.1.10.6"; hw-address = "9c:6b:00:19:ed:ff"; hostname = "server"; }
        { ip-address = "10.1.10.7"; hw-address = "b8:27:eb:cd:8e:3a"; hostname = "home-assistant"; }
        { ip-address = "10.1.10.8"; hw-address = "04:7c:16:76:a9:9c"; hostname = "desktop"; }
        { ip-address = "10.1.10.9"; hw-address = "54:b2:03:93:42:2e"; hostname = "tv"; }
        { ip-address = "10.1.10.10"; hw-address = "c0:f5:35:f4:95:bd"; hostname = "3d-printer"; }
      ];
    };
    guest = {
      id = 20;
      internet = true;
      dns = true;
      reservations = [];
    };
    iot = {
      id = 30;
      dns = true;
      reservations = [];
    };
    # TODO: this won't be needed once meshcentral and router are moved to proxmox
    management = {
      id = 100;
      reservations = [];
    };
  };
}
