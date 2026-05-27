{ inputs, ... }:

{
  flake.modules.nixos.common = { config, lib, ... }: {
    imports = with inputs.self.modules.nixos; [
      boot
      impermanence
      nix
    ] ++ [ inputs.self.modules.nixos.constants ];

    time.timeZone = "America/Toronto";
    networking = {
      domain = "willmckinnon.com";
      useNetworkd = true;
      wireless.enable = lib.mkDefault false;
    };
    system.stateVersion = config.system.nixos.release;
  };
}

