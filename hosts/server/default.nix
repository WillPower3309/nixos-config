{ config, pkgs, lib, ... }:

let
  hostKeyPath = /etc/ssh/ssh_host_ed25519_key;

in
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/headless
    ../../modules/arr.nix
    #../../modules/calibre.nix
    #../../modules/freshrss.nix
    #../../modules/immich.nix
    ../../modules/meshcentral.nix
    #../../modules/monitoring.nix
    ../../modules/nebula.nix
    ../../modules/nginx.nix
    ../../modules/radicale.nix
    ../../modules/plex.nix
    #../../modules/synapse.nix
    ../../modules/syncthing.nix
    ../../modules/tandoor-recipes.nix
    ../../modules/torrents.nix
  ];

  boot = {
    loader.lanzaboote.enable = false;
    supportedFilesystems = [ "zfs" ];

    # TODO: get nebula in initrd, good docs:
    # https://wiki.nixos.org/wiki/Remote_disk_unlocking
    # https://jyn.dev/remotely-unlocking-an-encrypted-hard-disk
    # TODO: secrets? different host key?
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

  networking.hostId = "7347e9d6"; # needed for zfs

  age.secrets.hashedRootPassword.file = ../../secrets/hashedRootPassword.age;

  users = {
    users.root = {
      hashedPasswordFile = config.age.secrets.hashedRootPassword.path;
      openssh.authorizedKeys.keys = [ (builtins.readFile ../../home/id_ed25519.pub) ];
    };
    mutableUsers = false;
  };

  services.openssh.hostKeys = lib.mkForce [{
    path = "/persist${(toString hostKeyPath)}"; # uses /persist instead of /nix/persist
    type = "ed25519";
  }];

  zramSwap.enable = true;

  services.nfs.server = {
    enable = true;
    exports = ''
      /export        10.1.10.8(rw,fsid=0,no_subtree_check)
      /export/photos 10.1.10.8(rw,insecure,no_subtree_check,all_squash,anonuid=65534,anongid=65534)
      /export/music  10.1.10.8(ro,insecure,no_subtree_check,all_squash,anonuid=65534,anongid=65534)
    '';
  };
  # open nfs ports
  networking.firewall.allowedTCPPorts = [ 2049 ];

  environment.etc."ssh/ssh_host_ed25519_key.pub".source = ./ssh_host_ed25519_key.pub;
}
