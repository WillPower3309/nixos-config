{
  flake.modules.nixos.organization = {
    services.gnome.evolution-data-server.enable = true;
  };

  flake.modules.homeManager.will = { pkgs, config, ... }: {
    home = {
      packages = with pkgs; [
        tutanota-desktop
        gnome-contacts
        gnome-calendar
      ];

      persistence."${config.constants.persistentDir}".directories = [
        ".config/evolution"
        ".cache/evolution"
      ];
    };
  };
}
