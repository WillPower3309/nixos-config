{ inputs, ... }:

{
  flake.modules.nixos.impermanence = { config, ... }:
  let
    # TODO: universal persistant dir, remove config usage
    persistentDir = if config.networking.hostName == "server" then "/persist" else "/nix/persist";

  in {
    imports = [ inputs.impermanence.nixosModules.impermanence ];

    environment = {
      persistence.${persistentDir} = {
        hideMounts = true;
        directories = [
          "/var/log"
          "/var/lib/nixos"
        ];
        files = [ "/etc/ssh/ssh_host_ed25519_key" ];
      };
    };
  };
}

