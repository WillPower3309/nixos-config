{ inputs, ... }:

{
  flake.modules.nixos.common = { config, lib, ... }: {
    imports = with inputs.self.modules.nixos; [
      boot
      impermanence
      nix
      root-user
    ] ++ [ inputs.self.constants ];

    time.timeZone = "America/Toronto";
    networking = {
      domain = config.constants.domain;
      useNetworkd = true;
      wireless.enable = lib.mkDefault false;
    };
    users.mutableUsers = false;
    system.stateVersion = config.system.nixos.release;

    # trust every host's key, under its name and fqdn (with port if not 22)
    programs.ssh.knownHosts = lib.mapAttrs (name: host: let
      hostCfg = host.config;
      port = builtins.head hostCfg.services.openssh.ports;
      names = [ name hostCfg.networking.fqdn ];
    in {
      hostNames = if port == 22 then names else map (n: "[${n}]:${toString port}") names;
      publicKey = inputs.self.lib.hostPubKey name;
    }) inputs.self.nixosConfigurations;

    # secrets.nix and knownHosts read each host's public key from here
    assertions = [{
      assertion = config.environment.etc ? "ssh/ssh_host_ed25519_key.pub";
      message = ''environment.etc."ssh/ssh_host_ed25519_key.pub".source must point to the host's public key'';
    }];
  };
}

