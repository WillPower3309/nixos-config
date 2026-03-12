{ config, pkgs, inputs, lib, ... }:

let
  hostKeyPath = /etc/ssh/ssh_host_ed25519_key;

in
{
  imports = [
    inputs.agenix.nixosModules.default
    inputs.impermanence.nixosModules.impermanence
    ./hardware-configuration.nix
    ../../modules/arr.nix
    #../../modules/calibre.nix
    ../../modules/freshrss.nix
    #../../modules/immich.nix
    ../../modules/meshcentral.nix
    ../../modules/monitoring.nix
    ../../modules/nebula.nix
    ../../modules/nginx.nix
    ../../modules/nix.nix
    ../../modules/radicale.nix
    ../../modules/plex.nix
    #../../modules/synapse.nix
    ../../modules/syncthing.nix
    ../../modules/tandoor-recipes.nix
    ../../modules/torrents.nix
  ];

  boot = {
    loader.systemd-boot.enable = true;
    supportedFilesystems = [ "zfs" ];

    initrd = {
      kernelModules = [ "igc" ]; # intel ethernet controller
      systemd.enable = true;

      network = {
        enable = true;
        ssh = {
          enable = true;
          port = 2222;
          authorizedKeys = lib.map (key: "command=\"/bin/systemd-tty-ask-password-agent\",restrict,pty ${key}") config.users.users.root.openssh.authorizedKeys.keys;
          hostKeys = [ (/persist + hostKeyPath) ];
        };
      };
    };
  };

  networking = {
    hostName = "server";
    hostId = "7347e9d6";
    wireless.enable = false;
  };

  age.secrets.hashedRootPassword.file = ../../secrets/hashedRootPassword.age;

  users = {
    users.root = {
      hashedPasswordFile = config.age.secrets.hashedRootPassword.path;
      openssh.authorizedKeys.keys = [ (builtins.readFile ../../home/id_ed25519.pub) ];
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

  zramSwap.enable = true;

  services.nfs.server = {
    enable = true;
    exports = ''
      /export        10.27.27.8(rw,fsid=0,no_subtree_check)
      /export/photos 10.27.27.8(rw,insecure,no_subtree_check,all_squash,anonuid=65534,anongid=65534)
      /export/music  10.27.27.8(ro,insecure,no_subtree_check,all_squash,anonuid=65534,anongid=65534)
    '';
  };
  # open nfs ports
  networking.firewall.allowedTCPPorts = [ 2049 ];

  # Set your time zone.
  time.timeZone = "America/Toronto";

  environment = {
    persistence."/persist" = {
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
