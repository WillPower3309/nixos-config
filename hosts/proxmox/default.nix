{ config, pkgs, impermanence, agenix, ... }:

let
  authorizedKey = (builtins.readFile ../../home/id_ed25519.pub);
  hostKeyPath = /etc/ssh/ssh_host_ed25519_key;

in
{
  imports = [
    agenix.nixosModules.default
    impermanence.nixosModules.impermanence
    ./disks.nix
    ../../modules/nix.nix
  ];

  networking = {
    hostName = "proxmox";
    wireless.enable = false;
  };

  boot.loader.systemd-boot = {
    enable = true;
    editor = false; # true allows gaining root access by passing init=/bin/sh as a kernel parameter
  };
  hardware.enableAllFirmware = true;

  age.secrets.hashedRootPassword.file = ../../secrets/hashedRootPassword.age;

  users = {
    users.root = {
      hashedPasswordFile = config.age.secrets.hashedRootPassword.path;
      openssh.authorizedKeys.keys = [ authorizedKey ];
    };
    mutableUsers = false;
  };

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
    hostKeys = [{
      path = "/persist/${(toString hostKeyPath)}";
      type = "ed25519";
    }];
  };

  # Set your time zone.
  time.timeZone = "America/Toronto";

  environment = {
    persistence."/nix/persist" = {
      hideMounts = true;
      directories = [
        "/var/log"
        "/var/lib/nixos"
      ];
      files = [ (toString hostKeyPath) ];
    };

    etc."ssh/ssh_host_ed25519_key.pub".source = ./ssh_host_ed25519_key.pub;
  };

  system.stateVersion = config.system.nixos.release;
}

