{ config, lib, pkgs, ... }:

{
  # TODO: https://github.com/NixOS/nixpkgs/issues/357201

  # login automatically
  # controversial, but with encrypted /, a password is required to get to this point anyway
  services.greetd = {
    enable = true;
    settings = rec {
      initial_session = {
        command = "dbus-run-session ${pkgs.swayfx}/bin/sway";
        user = "will";
      };
      default_session = initial_session;
    };
  };
}

