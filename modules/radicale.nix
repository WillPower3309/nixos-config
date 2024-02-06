{ config, ... }:

{
  age.secrets.radicaleHtpasswd = {
    file = ../secrets/radicaleHtpasswd.age;
    owner = "radicale";
    group = "radicale";
  };

  services.radicale = {
    enable = true;
    settings = {
      server = {
        hosts = [ "0.0.0.0:5232" "[::]:5232" ];
      };
      auth = {
        type = "htpasswd";
        htpasswd_filename = config.age.secrets.radicaleHtpasswd.path;
        htpasswd_encryption = "plain";
      };
      storage = {
        filesystem_folder = "/data/radicale";
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 5232 ];
}
