{ config, pkgs, impermanence, agenix, ... }:

let
  authorizedKeyPath = ../../home/id_ed25519.pub;
  hostKeyPath = /etc/ssh/ssh_host_ed25519_key;

in
{
  imports = [
    impermanence.nixosModules.impermanence
    agenix.nixosModules.default
    ./hardware-configuration.nix
    ../../modules/nix.nix
    ../../modules/syncthing-server.nix
    ../../modules/plex.nix
  ];

  boot = {
    loader.systemd-boot.enable = true;
    supportedFilesystems = [ "zfs" ];
    kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;

    initrd = {
      kernelModules = [ "e1000e" ];

      network = {
        enable = true;

        ssh = {
          enable = true;
          port = 2222;
          hostKeys = [ hostKeyPath ];
          authorizedKeys = [ (builtins.readFile authorizedKeyPath) ];
        };

        # auto load zfs password prompt on login & kill other prompt so boot can continue
        postCommands = ''
          cat <<EOF > /root/.profile
          if pgrep -x "zfs" > /dev/null
          then
            zfs load-key -a
            killall zfs
          else
            echo "zfs not running -- maybe the pool is taking some time to load"
          fi
          EOF
        '';
      };
    };
  };

  networking = {
    hostName = "server";
    hostId = "276fb82b";
    wireless.enable = false;
  };

  age.secrets.hashedRootPassword.file = ../../secrets/hashedRootPassword.age;

  users = {
    users.root.hashedPasswordFile = config.age.secrets.hashedRootPassword.path;
    mutableUsers = false;
  };

  # TODO use zramswap instad of swap partition (from zfs guide in README)

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
    hostKeys = [{
      path = "/persist/etc/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }];
  };

  users.users.root.openssh.authorizedKeys.keys = [ (builtins.readFile authorizedKeyPath) ];

  services.nfs.server = {
    enable = true;
    exports = ''
      /export        10.27.27.5(rw,fsid=0,no_subtree_check)
      /export/photos 10.27.27.5(rw,insecure,no_subtree_check,all_squash,anonuid=65534,anongid=65534)
    '';
  };
  # open nfs ports
  networking.firewall.allowedTCPPorts = [ 2049 ];

  # Set your time zone.
  time.timeZone = "America/Toronto";

  environment = {
    persistence."/persist" = {
      hideMounts = true;
      directories = [ "/var/log" ];
      files = [
        "/etc/machine-id" # used by systemd for journalctl
        (toString hostKeyPath)
      ];
    };

    etc."ssh/ssh_host_ed25519_key.pub".source = ./ssh_host_ed25519_key.pub;
  };

  system.stateVersion = "22.05";
}
