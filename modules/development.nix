{ config, pkgs, ... }:

{
  nixpkgs.config.android_sdk.accept_license = true;

  environment.systemPackages = with pkgs; [
    python3

    #android-studio
    #androidenv.androidPkgs_9_0.androidsdk

    # Language Servers
    rnix-lsp # nix
    clang-tools # c / cpp

    # C env
    gcc
    gnumake
  ];
}
