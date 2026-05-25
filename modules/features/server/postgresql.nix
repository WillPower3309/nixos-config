{ inputs, ... }:

{
  flake.modules.nixos.postgresql = { config, pkgs, ... }: {
    services.postgresql = {
      enable = true;
      dataDir = "/data/postgresql";
      package = pkgs.postgresql_16;
      ensureUsers = [{
        name = "root";
        ensureClauses.superuser = true;
      }];
    };
    system.activationScripts.postgresql-dir-creation.text = "install -m 750 -o postgres -g postgres -d ${config.services.postgresql.dataDir}";
  };
}
