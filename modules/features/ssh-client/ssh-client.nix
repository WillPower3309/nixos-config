{ inputs, ... }:

{
  flake.modules.homeManager.will = { pkgs, config, lib, nixosConfig, ... }: {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;

      settings = builtins.listToAttrs (lib.concatMap
        (net: lib.concatMap (reservation: let
          HostName = "${reservation.hostname}.${config.constants.domain}";
          User = "root";
        in [
          {
            name = "${reservation.hostname}";
            value = { inherit HostName User; };
          }
          {
            # TODO: collector pattern instead?
            name = "${reservation.hostname}-boot";
            value = {
              inherit HostName User;
              Port = config.constants.sshBootPort;
            };
          }
        ]) net.reservations)
        (builtins.attrValues inputs.self.networks)
      ) // {
        "lighthouse" = {
          HostName = "lighthouse.${config.constants.domain}";
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
