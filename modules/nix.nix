{ pkgs, ... }:

{
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
    # overlays = flake-overlays;
    config = {
      allowUnfree = true;
      oraclejdk.accept_license = true;
    };
  };
}
