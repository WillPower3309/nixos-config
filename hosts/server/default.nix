{ config, pkgs, impermanence, agenix, ... }:

let
  authorizedKey = (builtins.readFile ../../home/id_ed25519.pub);
  hostKeyPath = /etc/ssh/ssh_host_ed25519_key;

in
{
  imports = [
    agenix.nixosModules.default
    impermanence.nixosModules.impermanence
    ./hardware-configuration.nix
    ../../modules/arr.nix
    ../../modules/nebula.nix
    ../../modules/nginx.nix
    ../../modules/nix.nix
    ../../modules/radicale.nix
    ../../modules/plex.nix
    ../../modules/syncthing.nix
    ../../modules/tandoor-recipes.nix
    ../../modules/torrents.nix
  ];

  boot = {
    loader.systemd-boot.enable = true;
    supportedFilesystems = [ "zfs" ];
    kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;

    initrd = {
      kernelModules = [ "igc" ];

      network = {
        enable = true;

        ssh = {
          enable = true;
          port = 2222;
          hostKeys = [ (/persist + hostKeyPath) ];
          authorizedKeys = [ authorizedKey ];
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
    hostId = "7347e9d6";
    wireless.enable = false;
    nameservers = [ "194.242.2.4#base.dns.mullvad.net" ]; # TODO: across all hosts, use var
  };

#  services.resolved = {
#    enable = true;
#    dnssec = "true";
#    domains = [ "~." ];
#    fallbackDns = [ "194.242.2.4#base.dns.mullvad.net" ]; # TODO: across all hosts, use var
#    dnsovertls = "true";
#  };

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

  zramSwap.enable = true;

  services.nfs.server = {
    enable = true;
    exports = ''
      /export        10.27.27.5(rw,fsid=0,no_subtree_check)
      /export/photos 10.27.27.5(rw,insecure,no_subtree_check,all_squash,anonuid=65534,anongid=65534)
      /export/music  10.27.27.5(ro,insecure,no_subtree_check,all_squash,anonuid=65534,anongid=65534)
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

  system.stateVersion = "22.11";
}
