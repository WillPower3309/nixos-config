{ config, ... }:

let
  baseDomain = "${config.networking.hostName}.willmckinnon.com";
  address = "tandoor.${baseDomain}";

in {
  age.secrets.tandoorSecretKey.file = ./.. + builtins.toPath "/secrets/tandoorSecretKey.age";

  services = {
    tandoor-recipes = {
      enable = true;
      extraConfig.SECRET_KEY_FILE = config.age.secrets.tandoorSecretKey.path;
    };

    nginx.virtualHosts."${address}" = {
      locations."/".proxyPass = "http://127.0.0.1:${toString config.services.tandoor-recipes.port}";
      useACMEHost = baseDomain;
      forceSSL = true;
      kTLS = true;
    };
  };

  # TODO: more granularity
  environment.persistence."/persist".directories = [{
    directory = "/var/lib/private/";
    mode = "0700";
  }];
}

