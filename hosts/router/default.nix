{ config, lib, pkgs, inputs, ... }:

let
  authorizedKey = (builtins.readFile ../../home/id_ed25519.pub);
  hostKeyPath = "/etc/ssh/ssh_host_ed25519_key";

  wanInterface = "wan0";
  lanInterface = "lan0";

  # TODO: follow 10.1.<vlan>.<host>
  lanAddress = "10.27.27.1";
  lanCidr = "10.27.27.0/24";

  serverIp = "10.27.27.6";
  tvIp = "10.27.27.9";

in
# TODO: prometheus and grafana: https://thinglab.org/2024/12/nixos_router_software/
{
  imports = [
    inputs.agenix.nixosModules.default
    inputs.impermanence.nixosModules.impermanence
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

  boot.kernel.sysctl = {
    # enable IP forwarding
    "net.ipv4.conf.all.forwarding" = 1;

    # not using IPv6 yet
    "net.ipv6.conf.all.forwarding" = 0;
    "net.ipv6.conf.all.accept_ra" = 0;
    "net.ipv6.conf.all.autoconf" = 0;
    "net.ipv6.conf.all.use_tempaddr" = 0;

    # deny martian packets
#    "net.ipv4.conf.default.rp_filter" = 1;
#    "net.ipv4.conf.bond-wan.rp_filter" = 1;
#    "net.ipv4.conf.br-lan.rp_filter" = 1;

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

  # TODO: use tc-cake scheduler to avoid buffer bloat
  networking = {
    hostName = "router";
    domain = "willmckinnon.com";

    usePredictableInterfaceNames = false; # set interface names via services.udev.extraRules above
    useDHCP = false; # define per interface instead
    wireless.enable = false;
    networkmanager.enable = lib.mkForce false;
    firewall.enable = false; # use nftables instead
    useNetworkd = true;

    vlans = {
      trusted = {
        interface = lanInterface;
        id = 20;
      };
      guest = {
        interface = lanInterface;
        id = 90;
      };
      management = {
        interface = lanInterface;
        id = 100;
      };
    };

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

      # TODO: write reusable nix functions to reduce LOC for the following
      trusted.ipv4.addresses = [{
        address = "10.27.${toString config.networking.vlans.trusted.id}.1";
        prefixLength = 24;
      }];
      guest.ipv4.addresses = [{
        address = "10.27.${toString config.networking.vlans.guest.id}.1";
        prefixLength = 24;
      }];
      management.ipv4.addresses = [{
        address = "10.27.${toString config.networking.vlans.management.id}.1";
        prefixLength = 24;
      }];
    };

    # TODO: read https://www.mankier.com/8/nft#, Make sure I know what the following are: address families, hooks, tables, chains, rules, and sets
    nftables = {
      enable = true;
      ruleset = ''
        table ip filter {
          chain input {
            type filter hook input priority 0; policy drop;
            iifname { "${lanInterface}", "trusted" } accept comment "Allow trusted local network to access the router"
            iifname "${wanInterface}" ct state { established, related } accept comment "Allow established traffic"
            iifname "${wanInterface}" icmp type { echo-request, destination-unreachable, time-exceeded } counter accept comment "Allow select ICMP"
            iifname "${wanInterface}" counter drop comment "Drop all other unsolicited traffic from wan"
            iifname "lo" accept comment "allow loopback"
            tcp dport 22 accept comment "allow ssh"
          }
          chain forward {
            type filter hook forward priority 0; policy drop;
            iifname { "${lanInterface}", "trusted", "guest" } oifname { "${wanInterface}" } accept comment "Allow LAN to WAN"
            iifname { "${wanInterface}" } oifname { "${lanInterface}", "trusted", "guest" } ct state { established, related } accept comment "Allow established back to LANs"
            iifname { "trusted" } oifname { "management" } counter accept comment "Allow trusted to management"
            iifname { "management" } oifname { "trusted" } ct state { established, related } counter accept comment "Allow established & related back to trusted"
          }
        }

        table ip nat {
          chain postrouting {
            type nat hook postrouting priority 100; policy accept;
            oifname "${wanInterface}" masquerade
          }
        }

        table ip6 filter {
          chain input {
            type filter hook input priority 0; policy drop;
          }
          chain forward {
            type filter hook forward priority 0; policy drop;
          }
        }
      '';
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

      subnet4 = [
        {
          id = 1;
          subnet = lanCidr;
          pools = [{ pool = "10.27.27.16 - 10.27.27.254"; }];

          # optimize perf
          reservations-in-subnet = true;
          reservations-global = false;
          reservations-out-of-pool = true;

          reservations = [
            {
              ip-address = "10.27.27.5";
              hw-address = "f8:27:2e:0c:02:ef";
              hostname = "access-point";
            }
            {
              ip-address = serverIp;
              hw-address = "9c:6b:00:19:ed:ff";
              hostname = "server";
            }
            {
              ip-address = "10.27.27.7";
              hw-address = "b8:27:eb:cd:8e:3a";
              hostname = "home-assistant";
            }
            {
              ip-address = "10.27.27.8";
              hw-address = "04:7c:16:76:a9:9c";
              hostname = "desktop";
            }
            {
              ip-address = tvIp;
              hw-address = "54:b2:03:93:42:2e";
              hostname = "tv";
            }
            {
              ip-address = "10.27.27.10";
              hw-address = "c0:f5:35:f4:95:bd";
              hostname = "3d-printer";
            }
          ];

          option-data = [
            {
              name = "routers";
              data = lanAddress;
            }
            {
              name = "domain-name-servers";
              data = lanAddress;
            }
          ];
        }
        # TODO: make this a nix function
        # TODO: add trusted dhcp
        {
          id = config.networking.vlans.management.id;

          # optimize perf
          reservations-in-subnet = true;
          reservations-global = false;
          reservations-out-of-pool = true;

          subnet = "10.27.${toString config.networking.vlans.management.id}.0/24";
          pools = [{ pool = "10.27.${toString config.networking.vlans.management.id}.5 - 10.27.${toString config.networking.vlans.management.id}.254"; }];

          option-data = [
            {
              name = "routers";
              data = "10.27.${toString config.networking.vlans.management.id}.1";
            }
          ];
        }
      ];
    };
  };

  # use unbound for local queries
  services.resolved.enable = false;
  services.unbound = {
    enable = true;
    resolveLocalQueries = true;

    settings = {
      server = {
        interface = [
          "127.0.0.1"
          lanAddress
        ];
        access-control = [
          "0.0.0.0/0 refuse"
          "127.0.0.0/8 allow"
          "${lanCidr} allow"
        ];
        port = 53;
        hide-identity = true;
        hide-version = true;
        qname-minimisation = true;

        # Based on recommended settings in https://docs.pi-hole.net/guides/dns/unbound/#configure-unbound
        harden-glue = true;
        harden-dnssec-stripped = true;
        use-caps-for-id = false;
        prefetch = true;
        edns-buffer-size = 1232;

        private-domain = "willmckinnon.com"; # allow resolving these domains to private addresses
        local-zone = [
          ''"willmckinnon.com" typetransparent''
        ];
        local-data = [
          #''"server.willmckinnon.com IN A ${serverIp}"''
          ''"tv.willmckinnon.com IN A ${tvIp}"''
        ];
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

