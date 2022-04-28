{ config, pkgs, ... }:

{
  nixpkgs.config.android_sdk.accept_license = true;

  environment.systemPackages = with pkgs; [
    git
    python3

    android-studio
    androidenv.androidPkgs_9_0.androidsdk

    # Language Servers
    python-language-server # python
    rnix-lsp # nix
    clang-tools # c / cpp

    # C env
    gcc
    gnumake
  ];
}
