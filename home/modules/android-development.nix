{ pkgs, ... }:

{
  home = {
    packages = [ pkgs.android-studio ];

    persistence."/nix/persist/home/will".directories = [
      ".android"
      ".java"
      "Android"
      ".cache/Google"
      ".config/Google"
      ".local/share/Google"
    ];
  };
}

