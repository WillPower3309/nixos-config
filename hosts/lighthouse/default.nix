{ config, pkgs, agenix, ... }:

{
  imports = [
    agenix.nixosModules.default
    ../../modules/nix.nix
  ];

  # the ssh keys are set up on the digitalocean web ui
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  swapDevices = [{
    device = "/swap/swapfile";
    size = 1024 * 2; # 2 GB
  }];

  age.secrets = {
    nebulaCaCert.file = ../../secrets/nebulaCa.age;
    nebulaLighthouseCert.file = ../../secrets/nebulaLighthouseCert.age;
    nebulaLighthouseKey.file = ../../secrets/nebulaLighthouseKey.age;
  };

  services.nebula.networks.home = {
    enable = true;
    isLighthouse = true;
    cert = config.age.secrets.nebulaLighthouseCert.path; # lighthouse.crt
    key = config.age.secrets.nebulaLighthouseKey.path; # lighthouse.key
    ca = config.age.secrets.nebulaCaCert.path; # ca.crt
  };

  system.stateVersion = "23.05";
}
