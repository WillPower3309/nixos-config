{ pkgs, ... }:

{
  home = {
    packages = [ pkgs.obsidian ];

    persistence."/nix/persist/home/will".directories = [
      "notes"
      # TODO: replace below with declarative config
      ".config/obsidian"
    ];
  };
}
