{ inputs, ... }:

{
  flake.modules.nixos.tandoor = { config, ... }: let
    baseDomain = config.networking.fqdn;
    address = "tandoor.${baseDomain}";

  in {
    age.secrets.tandoorSecretKey.file = "${inputs.secrets}/tandoorSecretKey.age";

    services = {
      tandoor-recipes = {
        enable = true;
        extraConfig = {
          SECRET_KEY_FILE = config.age.secrets.tandoorSecretKey.path;
          GUNICORN_MEDIA = true; # TODO: use nginx?
        };
      };

      nginx.virtualHosts."${address}" = {
        locations."/".proxyPass = "http://127.0.0.1:${toString config.services.tandoor-recipes.port}";
        useACMEHost = baseDomain;
        forceSSL = true;
        kTLS = true;
      };
    };

    environment.persistence."/persist".directories = [{
      directory = "/var/lib/private/";
      mode = "0700";
    }];
  };
}
