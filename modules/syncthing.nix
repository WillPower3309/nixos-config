{ pkgs, ...}:

{
  # TODO: config with secrets
  services.syncthing = {
    enable = true;
    dataDir = "/nix/persist/syncthing";
    openDefaultPorts = true;
  };
}
