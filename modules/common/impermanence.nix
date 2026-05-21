{ config, inputs, ... }:

let
  # TODO: universal persistant dir, remove config usage
  persistentDir = if config.networking.hostName == "server" then "/persist" else "/nix/persist";

in {
  imports = [ inputs.impermanence.nixosModules.default ];

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
}

