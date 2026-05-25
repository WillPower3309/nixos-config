{ pkgs, ... }:

{
  home = {
    packages = with pkgs; [
      gnome-contacts
      gnome-calendar
    ];

    persistence."/nix/persist".directories = [
      ".config/evolution"
      ".cache/evolution"
    ];
  };
}
