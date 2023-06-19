{ pkgs, ... }:

{
  # TODO: add steam program here
  home = {
    packages = with pkgs; [
      lutris
      gamemode
      minecraft
    ];

    persistence."/nix/persist/home/will".directories = [
      ".local/share/Steam"
      ".minecraft"
    ];
  };
}
