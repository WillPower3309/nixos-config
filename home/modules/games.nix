{ pkgs, ... }:

{
  # TODO: add steam program here
  home = {
    packages = with pkgs; [
      lutris
      gamemode
    ];

    persistence."/nix/persist".directories = [
      ".local/share/Steam"
      ".minecraft"
    ];
  };
}
