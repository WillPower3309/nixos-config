{ inputs, lib, ... }:

let
  hostKeyPath = /etc/ssh/ssh_host_ed25519_key;

in
{
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "server";

  flake.modules.nixos.server = { config, pkgs, lib, ... }: {
    networking.hostName = "server";

    imports = with inputs.self.modules.nixos; [
      common
      ssh-server
      nebula
      syncthing
      arr
      meshcentral
      nginx
      plex
      radicale
      tandoor
      torrents
    ];

    boot = {
      lanzaboote.enable = false;
      supportedFilesystems = [ "zfs" ];

      initrd = {
        kernelModules = [ "igc" ];
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

    networking.hostId = "7347e9d6";

    age.secrets.hashedRootPassword.file = "${inputs.secrets}/hashedRootPassword.age";

    users = {
      users.root = {
        hashedPasswordFile = config.age.secrets.hashedRootPassword.path;
        openssh.authorizedKeys.keys = [ (builtins.readFile ../../../modules/home/id_ed25519.pub) ];
      };
      mutableUsers = false;
    };

    services.openssh.hostKeys = lib.mkForce [{
      path = "/persist${(toString hostKeyPath)}";
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
    networking.firewall.allowedTCPPorts = [ 2049 ];

    environment.etc."ssh/ssh_host_ed25519_key.pub".source = ./ssh_host_ed25519_key.pub;
  };
}
