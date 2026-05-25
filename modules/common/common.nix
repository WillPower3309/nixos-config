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
    system.stateVersion = config.system.nixos.release;
  };
}

