{ pkgs, ... }:

{
  services.gnome.evolution-data-server.enable = true;

  environment.systemPackages = with pkgs; [
    gnome.gnome-contacts
    gnome.gnome-calendar
  ];
}

