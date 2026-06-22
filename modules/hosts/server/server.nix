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
      # calibre
      # freshrss
      # immich
      meshcentral
      # monitoring
      nginx
      plex
      radicale
      # synapse
      tandoor
      torrents
    ];

    boot = {
      lanzaboote.enable = false;
      zfs.forceImportRoot = false;
      supportedFilesystems = [ "zfs" ];

      # TODO: get nebula in initrd, good docs:
      # https://wiki.nixos.org/wiki/Remote_disk_unlocking
      # https://jyn.dev/remotely-unlocking-an-encrypted-hard-disk
      # TODO: secrets? different host key?
      initrd = {
        kernelModules = [ "igc" ];  # intel ethernet controller
        systemd.enable = true;

        network = {
          enable = true;
          ssh = {
            enable = true;
            port = config.constants.sshBootPort;
            shell = "${pkgs.util-linux}/bin/nologin"; # block interactive shell access
            authorizedKeys = lib.map (
              key: "command=\"/bin/systemd-tty-ask-password-agent\",restrict,pty ${key}"
            ) config.users.users.root.openssh.authorizedKeys.keys;
            hostKeys = [ (config.constants.persistentDir + (toString hostKeyPath)) ];
          };
        };
      };
    };

    networking.hostId = "7347e9d6"; # needed for ZFS

    services.openssh.hostKeys = lib.mkForce [{
      path = "${config.constants.persistentDir}${(toString hostKeyPath)}";
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
    # open NFS ports
    networking.firewall.allowedTCPPorts = [ 2049 ];

    environment.etc."ssh/ssh_host_ed25519_key.pub".source = ./ssh_host_ed25519_key.pub;
  };
}
