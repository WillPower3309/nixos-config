{ config, lib, ... }:

{
  imports = [
    ./boot.nix
    ./impermanence.nix
    ./nix.nix
  ];

  time.timeZone = "America/Toronto";
  networking = {
    domain = "willmckinnon.com";
    useNetworkd = true;
    wireless.enable = lib.mkDefault false;
  };
  system.stateVersion = config.system.nixos.release;
}

