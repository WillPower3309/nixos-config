{ pkgs, ... }:

{
  home = {
    packages = [ pkgs.obsidian ];

    persistence."/nix/persist".directories = [
      "notes"
      # TODO: replace below with declarative config
      ".config/obsidian"
    ];
  };
}
