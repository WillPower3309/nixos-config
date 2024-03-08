{ config, ... }:

{
  # https://www.cyberciti.biz/faq/issue-lets-encrypt-wildcard-certificate-with-acme-sh-and-cloudflare-dns/#Getting_Cloudflare_API_key
  age.secrets.acme.file = ../secrets/acme.age;

  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "contact@willmckinnon.com";
      credentialsFile = config.age.secrets.acme.path;
      dnsProvider = "digitalocean";
    };
  };

  services.nginx = {
    enable = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedGzipSettings = true;

    # restrict base domain
    virtualHosts."${config.networking.hostName}.willmckinnon.com" = {
      locations."/".return = 403;
      default = true;
    };
  };

  environment.persistence."/persist".directories = [{ directory = "/var/lib/acme"; user = "acme"; group = "acme"; }];

  users.groups.acme.members = [ "nginx" ];

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
