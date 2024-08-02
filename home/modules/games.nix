{ pkgs, ... }:

{
  # TODO: add steam program here
  home = {
    packages = with pkgs; [
      lutris
      gamemode
    ];

    persistence."/nix/persist/home/will".directories = [
      ".local/share/Steam"
      ".minecraft"
    ];
  };
}
