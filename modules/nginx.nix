{ config, ... }:

let
  domainName = "${config.networking.hostName}.willmckinnon.com";
  acmeDataDir = "/var/lib/acme";

in
{
  age.secrets.acme.file = ../secrets/acme.age;

  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "contact@willmckinnon.com";
      credentialsFile = config.age.secrets.acme.path;
      dnsProvider = "cloudflare";
    };

    certs."${domainName}".domain = "*.${domainName}"; # wildcard cert
  };

  services.nginx = {
    enable = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedGzipSettings = true;

    # restrict base domain
    virtualHosts."${domainName}" = {
      locations."/".return = 403;
      default = true;
    };
  };

  environment.persistence."/persist".directories = [{ directory = acmeDataDir; user = "acme"; group = "acme"; }];

  users.groups.acme.members = [ "nginx" ];

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
