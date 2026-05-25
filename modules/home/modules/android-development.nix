{ inputs, ... }:

{
  flake.modules.homeManager.android-development = { pkgs, ... }: {
    home = {
      packages = with pkgs; [ android-studio android-tools ];

      persistence."/nix/persist".directories = [
        ".android"
        ".java"
        "Android"
        ".cache/Google"
        ".config/Google"
        ".local/share/Google"
      ];
    };
  };
}
