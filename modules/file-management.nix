{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    ripgrep
    nautilus
    unzip
    udiskie
  ];

  services.udisks2.enable = true; # needed for udiskie
}
