{ pkgs, ... }:

{
  home = {
    packages = with pkgs; [
      gnome-contacts
      gnome-calendar
    ];
    
    persistence."/nix/persist/home/will".directories = [
      ".config/evolution"
      ".cache/evolution"
    ];
  };
}
