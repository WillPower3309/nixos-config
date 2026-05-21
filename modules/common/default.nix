{ config, ... }:

{
  imports = [
    ./impermanence.nix
    ./nix.nix
  ];

  time.timeZone = "America/Toronto";
  networking.domain = "willmckinnon.com";
  system.stateVersion = config.system.nixos.release;
}

