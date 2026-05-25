{ inputs, ... }:

{
  flake.modules.nixos.nix = {
    nix = {
      extraOptions = ''
        experimental-features = nix-command flakes
      '';

      gc = {
        automatic = true;
        dates = "thursday";
        options = "--delete-older-than 8d";
      };
    };

    nixpkgs = {
      config = {
        allowUnfree = true;
        oraclejdk.accept_license = true;
      };
    };
  };
}

