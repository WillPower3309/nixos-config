{
  flake.modules.nixos.organization = { pkgs, ... }: {
    services.gnome.evolution-data-server.enable = true;
    environment.systemPackages = [ pkgs.tutanota-desktop ];
  };
}
