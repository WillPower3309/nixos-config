{ config, inputs, lib, ... }:

let
  hostName = "reverse-proxy";
  macAddress = "02:00:00:00:00:03";

  reservations = lib.concatMap (net: net.reservations) (lib.attrValues config.flake.networks);

  # a VM is reached at the reservation for its first NIC
  vmAddress = vmName: microvm:
    let
      mac = if microvm.vfs != [] then (lib.head microvm.vfs).mac
        else throw "microvm ${vmName} sets proxy but has no NIC";
    in (lib.findFirst (reservation: reservation.hw-address == mac)
      (throw "microvm ${vmName} has no reservation for ${mac}") reservations).ip-address;

  proxies = lib.concatLists (lib.mapAttrsToList (vmName: microvm:
    lib.mapAttrsToList (name: proxy: proxy // { inherit name; upstream = "${proxy.scheme}://${vmAddress vmName microvm}:${toString proxy.port}"; }) microvm.proxy
  ) config.flake.microvms);
  proxyNames = map (proxy: proxy.name) proxies;

in {
  flake.microvms.${hostName}.vfs = [{ mac = macAddress; vlan = 10; }];

  flake.networks."10".reservations = [{
    ip-address = "10.1.10.13";
    hostname = hostName;
    hw-address = macAddress;
  }];

  flake.modules.nixos.${hostName} = { config, ... }: {
    imports = [
      ./_common.nix
      inputs.microvm.nixosModules.microvm
      inputs.self.constants
    ];

    assertions = [{
      assertion = lib.allUnique proxyNames;
      message = "microvm proxy names must be unique: ${toString proxyNames}";
    }];

    networking = {
      inherit hostName;
      firewall.allowedTCPPorts = [ 80 ];
    };

    microvm = {
      vcpu = 1;
      mem = 512;
    };

    # TODO: ACME (wildcard cert via DNS-01, needs a VM age identity) and forceSSL
    services.nginx = {
      enable = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedGzipSettings = true;

      virtualHosts = {
        "_" = {
          default = true;
          locations."/".return = 403;
        };
      } // lib.listToAttrs (map (proxy: lib.nameValuePair "${proxy.name}.${config.constants.domain}" {
        locations."/" = {
          proxyPass = proxy.upstream;
          proxyWebsockets = true;
        };
      }) proxies);
    };
  };
}
