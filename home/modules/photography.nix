{ pkgs, ... }:

{
  home = {
    packages = with pkgs; [
      darktable
      imagemagick
    ];

    persistence."/nix/persist/home/will".files = [
      ".config/darktable/data.db"
      ".config/darktable/library.db"
    ];
  };
}
