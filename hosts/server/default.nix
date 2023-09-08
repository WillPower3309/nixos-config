{ config, pkgs, impermanence, agenix, ... }:

let
  desktopKey = "";
  surfaceKey = "";

in
{
  imports = [
    impermanence.nixosModules.impermanence
    agenix.nixosModules.default
    ./hardware-configuration.nix
    ../../modules/nix.nix
#    ../../modules/containerized-services/plex.nix
#    ../../modules/containerized-services/syncthing.nix
  ];

  age.secrets = {
    desktopPrivateKey.file = ../../secrets/desktopPrivateKey.age;
  };

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

          hostKeys = [ /persist/etc/ssh/ssh_host_rsa_key ];
          authorizedKeys = [
#            "$(cat ${config.age.secrets.desktopPrivateKey.path})"
            "${desktopKey}"
            "${surfaceKey}"
          ];
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

  users = {
    users.root.initialPassword = "1012917";
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
    hostKeys = [
      # TODO: remove rsa key
      {
        bits = 4096;
        path = "/persist/etc/ssh/ssh_host_rsa_key";
        type = "rsa";
      }
      {
        path = "/persist/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
  };

  users.users.root.openssh.authorizedKeys = {
    keys = [
      "${desktopKey}"
      "${surfaceKey}"
      "$(cat ${config.age.secrets.desktopPrivateKey.path})"
    ];
#    keyFiles = [
#      config.age.secrets.desktopPrivateKey.path
#    ];
  };

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

  environment.persistence."/persist" = {
    directories = [
      "/var/log"
      "/etc/ssh"
    ];
    files = [ "/etc/machine-id" ]; # used by systemd for journalctl
  };

  system.stateVersion = "22.05";
}
