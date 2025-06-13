{ config, pkgs, ... }:

let
  baseDomain = "${config.networking.hostName}.willmckinnon.com";
  libraryDir = "/data/books";
  userDbDir = "/persist/etc/calibre-server";
  userDbFilePath = "${userDbDir}/users.sqlite";

in {
  services = {
    calibre-server = {
      enable = true;
      port = 8181; # 8080 likely used by immich
      host = "0.0.0.0";
      libraries = [ libraryDir ];
      openFirewall = true; # koreader needs port + IP address to connect to calibre

      auth = {
        enable = true;
        mode = "basic";
        userDb = userDbFilePath;
      };
    };

    nginx.virtualHosts."calibre.${baseDomain}" = {
      locations."/".proxyPass = "http://127.0.0.1:${toString config.services.calibre-server.port}";
      useACMEHost = baseDomain;
      forceSSL = true;
      kTLS = true;

      extraConfig = ''
        client_max_body_size 128M;
      '';
    };
  };

  age.secrets.calibrePassword.file = ../secrets/calibrePassword.age;

  system.activationScripts = {
    calibre-library-init.text = ''
      install -d -o ${config.services.calibre-server.user} -g ${config.services.calibre-server.group} ${libraryDir}
      if [ -z "$(ls -A ${libraryDir})" ]; then
        touch ${libraryDir}/metadata.db
      fi
    '';
    calibre-user-db-init.text = ''
      install -d -o ${config.services.calibre-server.user} -g ${config.services.calibre-server.group} ${userDbDir}
      if [ -z "$(ls -A ${userDbDir})" ]; then
        ${pkgs.calibre}/bin/calibre-server --userdb ${userDbFilePath} --manage-users add will $(cat ${config.age.secrets.calibrePassword.path})
      fi
    '';
  };
}

