{ config, lib, agenix, impermanence, ... }:

let
  authorizedKey = (builtins.readFile ../../home/id_ed25519.pub);
  hostKeyPath = "/etc/ssh/ssh_host_ed25519_key";

  wanInterface = "wan0";
  lanInterface = "lan0";

  lanAddress = "10.27.27.1";

in
# TODO: prometheus and grafana: https://thinglab.org/2024/12/nixos_router_software/
{
  imports = [
    agenix.nixosModules.default
    impermanence.nixosModules.impermanence
    ./disks.nix
    ./hardware-configuration.nix
    ../../modules/nix.nix
  ];

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
      path = "/nix/persist${hostKeyPath}";
      type = "ed25519";
    }];
  };

  powerManagement.cpuFreqGovernor = "powersave";

  boot = {
    loader.systemd-boot.enable = true;
    initrd.systemd.enable = true;
  };

  # enable IP forwarding
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = true;

    # TODO: deny martian packets

    # Not using IPv6 yet
    "net.ipv6.conf.all.forwarding" = false;
    "net.ipv6.conf.all.accept_ra" = false;
    "net.ipv6.conf.all.autoconf" = false;
    "net.ipv6.conf.all.use_tempaddr" = false;

    # On WAN, allow IPv6 autoconfiguration and tempory address use.
    "net.ipv6.conf.${wanInterface}.accept_ra" = 2;
    "net.ipv6.conf.${wanInterface}.autoconf" = 1;
  };

  services = {
    udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="60:be:b4:00:85:28", NAME="${wanInterface}"
      ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="60:be:b4:00:85:29", NAME="${lanInterface}"
      ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="60:be:b4:00:85:2a", NAME="opt0"
      ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="60:be:b4:00:85:2b", NAME="opt1"
    '';
  };

  networking = {
    hostName = "router";

    usePredictableInterfaceNames = false; # set interface names via services.udev.extraRules above
    useDHCP = false;
    wireless.enable = false;
    networkmanager.enable = lib.mkForce false;

    interfaces = {
      "${wanInterface}" = {
        useDHCP = true;
        tempAddress = "disabled"; # Disable Temp Addresses for ISP's sake.
      };
      "${lanInterface}" = {
        useDHCP = false;
        ipv4.addresses = [{
          address = lanAddress;
          prefixLength = 24;
        }];
      };
    };

    # TODO: nftables hardware accel
    nat.enable = false;
    firewall.enable = false;
    nftables = {
      enable = true;
      tables = {
        filterV4 = {
          family = "ip";
          content = ''
            chain input {
              type filter hook input priority 0; policy drop;
              iifname "lo" accept comment "allow loopback traffic"
              iifname "${lanInterface}" accept comment "allow traffic from ${lanInterface}"
              iifname "${wanInterface}" counter drop comment "drop all other traffic from ${wanInterface}"
              ct state vmap { established : accept, related : accept, invalid : drop } comment "allow traffic from established and related packets, drop invalid"
            }
            chain forward {
              type filter hook forward priority 0; policy drop;
              ct state vmap { established : accept, related : accept, invalid : drop }
              iifname "${lanInterface}" accept comment "allow ${lanInterface} connections to go wherever"
              counter drop
            }
          '';
        };

        filterV6 = {
          family = "ip6";
          content = ''
            chain input {
              type filter hook input priority 0; policy drop;
            }
            chain forward {
              type filter hook forward priority 0; policy drop;
            }
          '';
        };

        natV4 = {
          family = "ip";
          content = ''
            chain prerouting {
              type nat hook prerouting priority filter; policy accept;
              iifname "${lanInterface}" udp dport 53 counter redirect to 53 comment "redirect DNS queries to the router's DNS"
              iifname "${lanInterface}" tcp dport 53 counter redirect to 53 comment "redirect DNS queries to the router's DNS"
            }

            chain postrouting {
              type nat hook postrouting priority 100; policy accept;
              oifname "${wanInterface}" masquerade comment "replace source address with ${wanInterface} IP address"
            }
          '';
        };
      };
    };
  };

  services.kea.dhcp4 = {
    enable = true;
    settings = {
      interfaces-config.interfaces = [ lanInterface ];

      lease-database = {
        name = "/var/lib/kea/kea-dhcp4-leases.csv";
        type = "memfile";
        persist = true;
        lfc-interval = 3600;
      };

      valid-lifetime = 4000;
      renew-timer = 1000;
      rebind-timer = 2000;

      subnet4 = [{
        id = 1;
        subnet = "10.27.27.0/24";
        pools = [{
          pool = "10.27.27.16 - 10.27.27.254";
        }];

        # optimize perf
        reservations-in-subnet = true;
        reservations-global = false;
        reservations-out-of-pool = true;

        reservations = [
          {
            ip-address = "10.27.27.2";
            hw-address = "f8:27:2e:0c:02:ef";
            hostname = "access-point";
          }
          {
            ip-address = "10.27.27.3";
            hw-address = "9c:6b:00:19:ed:ff";
            hostname = "server";
          }
          {
            ip-address = "10.27.27.4";
            hw-address = "b8:27:eb:cd:8e:3a";
            hostname = "home-assistant";
          }
          {
            ip-address = "10.27.27.5";
            hw-address = "c8:7f:54:0a:4b:d2";
            hostname = "desktop";
          }
          {
            ip-address = "10.27.27.6";
            hw-address = "d8:3a:dd:4b:ed:01";
            hostname = "tv";
          }
#          {
#            ip-address = "10.27.27.15";
#            hostname = "nixos-install";
#          }
        ];

        option-data = [{
          name = "routers";
          data = lanAddress;
        }];
      }];
    };
  };

  # use unbound for local queries
  services.resolved.enable = false;

  services.unbound = {
    enable = true;
    resolveLocalQueries = true;

    settings = {
      server = {
        interface = [ lanAddress ];
        port = 53;
        hide-identity = true;
        hide-version = true;

        # Based on recommended settings in https://docs.pi-hole.net/guides/dns/unbound/#configure-unbound
        harden-glue = true;
        harden-dnssec-stripped = true;
        use-caps-for-id = false;
        prefetch = true;
        edns-buffer-size = 1232;
      };

      forward-zone = [{
        name = ".";
        # don't fallback to recursive DNS
        forward-first = false;

        forward-tls-upstream = true;
        # TODO: use mullvad
        forward-addr = [
          "1.1.1.1@853#cloudflare-dns.com"
          "1.0.0.1@853#cloudflare-dns.com"
        ];
      }];
    };
  };

  environment = {
    persistence."/nix/persist" = {
      hideMounts = true;
      directories = [
        "/var/log"
        "/var/lib/nixos"
      ];
      files = [ hostKeyPath ];
    };

    etc."ssh/ssh_host_ed25519_key.pub".source = ./ssh_host_ed25519_key.pub;
  };

  time.timeZone = "America/Toronto";
  system.stateVersion = config.system.nixos.release;
}
