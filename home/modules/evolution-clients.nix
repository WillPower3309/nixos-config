{ pkgs, ... }:

{
  home = {
    packages = with pkgs; [
      gnome.gnome-contacts
      gnome.gnome-calendar
    ];
    
    persistence."/nix/persist/home/will".directories = [
      ".config/evolution"
      ".cache/evolution"
    ];
  };
}
