{ pkgs, ... }:

{
  home = {
    packages = with pkgs; [
      darktable
      imagemagick
    ];

    # TODO: Store on nas
    # TODO: module
    persistence."/nix/persist/home/will".files = [
      ".config/darktable/data.db"
      ".config/darktable/library.db"
    ];
  };
}

