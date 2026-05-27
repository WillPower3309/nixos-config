{
  flake.modules.nixos.organization = {
    services.gnome.evolution-data-server.enable = true;
  };

  flake.modules.homeManager.will = { pkgs, ... }: {
    home = {
      packages = with pkgs; [
        tutanota-desktop
        gnome-contacts
        gnome-calendar
      ];

      persistence."/nix/persist".directories = [
        ".config/evolution"
        ".cache/evolution"
      ];
    };
  };
}
