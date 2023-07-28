{ pkgs, ... }:

{
  virtualisation.docker = {
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
    enableOnBoot = false;
    # TODO: autoprune
  };

  environment = {
    systemPackages = with pkgs; [ distrobox ];

    persistence."/nix/persist".directories = [
      "/var/lib/docker"
      "/var/lib/docker/overlay2"
    ];
  };
}
