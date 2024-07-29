{ config, lib, pkgs, ... }:

let
  immichDir = "/data/immich";
  directories = {
    config = "${immichDir}/config";
    photos = "${immichDir}/photos";
    postgres = "${immichDir}/postgres";
  };
  dirCreationCommandList = lib.attrsets.mapAttrsToList(_: dir: "install -d ${dir}") directories;

  dbUser = "postgres";
  dbPassword = "postgres";
  dbName = "immich";

in {
  # TODO owner / perms?
  system.activationScripts.immich-dirs-creation.text = lib.strings.concatMapStrings (cmd: "${cmd}\n") dirCreationCommandList;

  networking.firewall.allowedTCPPorts = [ 8080 ];

  environment.persistence."/persist".directories = ["/var/lib/containers"];
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };
  
  # Immich
  virtualisation.oci-containers.containers = {
    immich = {
      autoStart = true;
      image = "ghcr.io/imagegenius/immich:latest";
      volumes = [
        "${directories.config}:/config"
        "${directories.photos}:/photos"
      ];
      ports = [ "8080:8080" ];
      environment = {
        PUID = "1000";
        PGID = "1000";
        TZ = "America/Toronto";
        DB_HOSTNAME = "postgres14";
        DB_USERNAME = dbUser;
        DB_PASSWORD = dbPassword;
        DB_DATABASE_NAME = dbName;
        REDIS_HOSTNAME = "redis";
      };
      extraOptions = [ "--network=host" ];
    };

    redis = {
      autoStart = true;
      image = "redis";
      ports = [ "6379:6379" ];
      extraOptions = [ "--network=host" ];
    };

    postgres14 = {
      autoStart = true;
      image = "tensorchord/pgvecto-rs:pg14-v0.2.0";
      ports = [ "5432:5432" ];
      volumes = [ "${directories.postgres}:/var/lib/postgresql/data" ];
      environment = {
        POSTGRES_USER = dbUser;
        POSTGRES_PASSWORD = dbPassword;
        POSTGRES_DB = dbName;
      };
      extraOptions = [ "--network=host" ];
    };
  };

}
