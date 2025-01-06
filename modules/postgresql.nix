{ config, ...}:

{
  # TODO: only have this do things if postgresql.enable = true?
  # TODO: use postgresql backup to /data instead?
  # TODO: add upstream and use user / group value from services.postgresql
  services.postgresql.dataDir = "/data/postgresql";
  system.activationScripts.postgresql-dir-creation.text = "install -m 750 -o postgres -g postgres -d ${config.services.postgresql.dataDir}";
}

