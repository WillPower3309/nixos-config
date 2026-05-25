{ inputs, ... }:

{
  flake.modules.nixos.ssh-server = { config, ... }: {
    services.openssh = {
      enable = true;
      openFirewall = config.networking.firewall.enable;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
      hostKeys = [{
        path = "${config.constants.persistentDir}/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }];
    };
  };
}
