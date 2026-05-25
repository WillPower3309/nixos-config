{ inputs, ... }:

{
  flake.modules.nixos.impermanence = { config, ... }: {
    imports = [ inputs.impermanence.nixosModules.impermanence ];

    environment = {
      persistence.${config.constants.persistentDir} = {
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

