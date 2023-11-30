{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    ripgrep
    gnome3.nautilus
    unzip
    udiskie
  ];

  services.udisks2.enable = true; # needed for udiskie
}
