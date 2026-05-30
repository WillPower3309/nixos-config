{ inputs, ... }:

let
  networks = inputs.self.networks;
in {
  flake.modules.homeManager.will = { pkgs, config, lib, nixosConfig, ... }: {
    programs.ssh = {
      enable = true;

      settings = builtins.listToAttrs (lib.concatMap
        (net: map (reservation: {
          name = "${reservation.hostname}*";
          value = {
            HostName = "${reservation.hostname}.willmckinnon.com";
            User = "root";
          };
        }) net.dhcp.reservations)
        (builtins.attrValues networks)
      ) // {
        "*-boot" = {
          Port = 2222;
        };

        "lighthouse" = {
          HostName = "lighthouse.willmckinnon.com";
          User = "root";
          Port = 2222;
        };
      };
    };

    home = {
      persistence."${config.constants.persistentDir}".files = [
        ".ssh/id_ed25519"
        ".ssh/known_hosts"
      ];
      file.".ssh/id_ed25519.pub".source = ./id_ed25519.pub;
    };
  };
}
