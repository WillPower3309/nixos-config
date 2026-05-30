{ inputs, ... }:

{
  flake.modules.nixos.nginx = { config, ... }: let
    domainName = config.networking.fqdn;
    acmeDataDir = "/var/lib/acme";

  in {
    age.secrets.acme.file = ./acme.age;

    security.acme = {
      acceptTerms = true;
      defaults = {
        email = "contact@willmckinnon.com";
        environmentFile = config.age.secrets.acme.path;
        dnsProvider = "cloudflare";
      };

      certs."${domainName}".domain = "*.${domainName}";
    };

    services.nginx = {
      enable = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      recommendedGzipSettings = true;

      virtualHosts."${domainName}" = {
        locations."/".return = 403;
        default = true;
      };
    };

    environment.persistence."${config.constants.persistentDir}".directories = [
      { directory = acmeDataDir; user = "acme"; group = "acme"; }
    ];

    users.groups.acme.members = [ "nginx" ];

    networking.firewall.allowedTCPPorts = [ 80 443 ];
  };
}
