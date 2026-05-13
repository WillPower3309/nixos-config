{ config, lib, pkgs, inputs, ... }:

# TODO: set up reverse DNS pointer records (PTR) in unbound so devices can be recognized via hostname instead of IP
# TODO: prometheus and grafana, map Prometheus metrics collection exporters to trace live CAKE drop rates and queue latencies onto Grafana
let
  authorizedKey = (builtins.readFile ../../home/id_ed25519.pub);
  hostKeyPath = "/etc/ssh/ssh_host_ed25519_key";

  wanInterface = "wan0";
  lanInterface = "lan0";

  # should be 90-95% of the true limit (needed for cake)
  wanDownloadSpeed = "900mbit";
  wanUploadSpeed = "900mbit";

  tvIp = "10.1.20.9";

  networks = {
    # TODO: remove default?
    default = {
      id = 27; # TODO: technically this should be 1
      dhcp = {
        enable = true;
        reservations = [
          { ip-address = "10.1.27.5"; hw-address = "f8:27:2e:0c:02:ef"; hostname = "access-point"; }
          { ip-address = "10.1.27.6"; hw-address = "9c:6b:00:19:ed:ff"; hostname = "server"; }
          { ip-address = "10.1.27.7"; hw-address = "b8:27:eb:cd:8e:3a"; hostname = "home-assistant"; }
          { ip-address = "10.1.27.8"; hw-address = "04:7c:16:76:a9:9c"; hostname = "desktop"; }
          { ip-address = "10.1.27.9"; hw-address = "54:b2:03:93:42:2e"; hostname = "tv"; }
          { ip-address = "10.1.27.10"; hw-address = "c0:f5:35:f4:95:bd"; hostname = "3d-printer"; }
        ];
      };
    };
    trusted = {
      id = 20;
      dhcp = {
        enable = true;
        reservations = [
          { ip-address = "10.1.20.5"; hw-address = "f8:27:2e:0c:02:ef"; hostname = "access-point"; }
          { ip-address = "10.1.20.6"; hw-address = "9c:6b:00:19:ed:ff"; hostname = "server"; }
          { ip-address = "10.1.20.7"; hw-address = "b8:27:eb:cd:8e:3a"; hostname = "home-assistant"; }
          { ip-address = "10.1.20.8"; hw-address = "04:7c:16:76:a9:9c"; hostname = "desktop"; }
          { ip-address = tvIp; hw-address = "54:b2:03:93:42:2e"; hostname = "tv"; }
          { ip-address = "10.1.20.10"; hw-address = "c0:f5:35:f4:95:bd"; hostname = "3d-printer"; }
        ];
      };
    };
    guest = {
      id = 30;
      dhcp = { enable = true; reservations = []; };
    };
    management = {
      id = 100;
      dhcp = { enable = false; reservations = []; };
    };
  };

in
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

    kernel.sysctl = {
      # enable IP forwarding
      "net.ipv4.conf.all.forwarding" = 1;

      # not using IPv6 yet
      "net.ipv6.conf.all.forwarding" = 0;
      "net.ipv6.conf.all.accept_ra" = 0;
      "net.ipv6.conf.all.autoconf" = 0;
      "net.ipv6.conf.all.use_tempaddr" = 0;

      # Fix Unbound socket receive buffer warnings safely via sysctl adjustments
      "net.core.rmem_max" = 1048576;

      # deny martian packets
    #    "net.ipv4.conf.default.rp_filter" = 1;
    #    "net.ipv4.conf.all.rp_filter" = 1;

      # On WAN, allow IPv6 autoconfiguration and tempory address use.
      "net.ipv6.conf.${wanInterface}.accept_ra" = 2;
      "net.ipv6.conf.${wanInterface}.autoconf" = 1;
    };
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
    domain = "willmckinnon.com"; # TODO: define this across all hosts
    usePredictableInterfaceNames = false; # set interface names via services.udev.extraRules above
    useDHCP = false; # define per interface instead
    wireless.enable = false;
    networkmanager.enable = lib.mkForce false;
    firewall.enable = false; # use nftables instead
    useNetworkd = true;

    # TODO: read https://www.mankier.com/8/nft
    # TODO: from above, make sure I know what the following are: address families, hooks, tables, chains, rules, and sets
    nftables = {
      enable = true;
      ruleset = ''
        table ip filter {
          chain input {
            type filter hook input priority 0; policy drop;

            iifname { "${lanInterface}", "trusted" } accept comment "Allow trusted local network to access the router"

            iifname "guest" udp dport { 53, 67 } accept comment "Allow guest DNS, DHCP"
            iifname "guest" tcp dport 53 accept comment "Allow guest DNS over TCP"

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

  systemd.network = {
    enable = true;
    wait-online = {
      enable = true;
      anyInterface = false;
      extraArgs = [ "-i" "${wanInterface}" ];
    };

    netdevs = lib.mapAttrs' (name: net: lib.nameValuePair "30-vlan${toString net.id}" {
      netdevConfig = {
        Kind = "vlan";
        Name = "${lanInterface}.${toString net.id}";
      };
      vlanConfig.Id = net.id;
    }) (lib.filterAttrs (name: net: name != "default") networks);

    networks = {
      "10-wan" = {
        matchConfig.Name = wanInterface;
        networkConfig = {
          DHCP = "ipv4";
          IPv6PrivacyExtensions = "no";
        };
        linkConfig.RequiredForOnline = "yes";
      };

      # Physical LAN Base Trunk (Hosts the "default" untagged network + tags others)
      "20-lan0" = {
        matchConfig.Name = lanInterface;
        networkConfig = {
          Address = "10.1.27.1/24";
          VLAN = lib.mapAttrsToList (name: net: "${lanInterface}.${toString net.id}")
            (lib.filterAttrs (name: net: name != "default") networks);
        };
        linkConfig.RequiredForOnline = "no";
      };
    } // (lib.mapAttrs' (name: net: lib.nameValuePair "25-vlan${toString net.id}" {
      # Virtual VLAN Interfaces Egress
      matchConfig.Name = "${lanInterface}.${toString net.id}";
      networkConfig.Address = "10.1.${toString net.id}.1/24";
      linkConfig.RequiredForOnline = "no";
    }) (lib.filterAttrs (name: net: name != "default") networks));
  };

  services.kea.dhcp4 = {
    enable = true;
    settings = {
      interfaces-config.interfaces = [ lanInterface ]
        ++ lib.mapAttrsToList (name: net: "${lanInterface}.${toString net.id}") (lib.filterAttrs (name: net: name != "default" && net.dhcp.enable) networks);

      lease-database = {
        name = "/var/lib/kea/kea-dhcp4-leases.csv";
        type = "memfile";
        persist = true;
        lfc-interval = 3600;
      };

      valid-lifetime = 4000;
      renew-timer = 1000;
      rebind-timer = 2000;

      subnet4 = lib.mapAttrsToList (name: net: {
        id = net.id;
        subnet = "10.1.${toString net.id}.0/24";
        pools = if net.dhcp.enable then [{
          # set a reservation = number of reservations + 2 (router & switch)
          pool = "10.1.${toString net.id}.${toString (builtins.length net.dhcp.reservations + 2)} - 10.1.${toString net.id}.254";
        }] else [ ];

        reservations-in-subnet = net.dhcp.enable;
        reservations-global = false;
        reservations-out-of-pool = net.dhcp.enable;
        reservations = net.dhcp.reservations;

        option-data = if net.dhcp.enable then [
          { name = "routers"; data = "10.1.${toString net.id}.1"; }
          { name = "domain-name-servers"; data = "10.1.${toString net.id}.1"; }
        ] else [ ];
      }) networks;
    };
  };

  services.resolved.enable = false;
  services.unbound = {
    enable = true;
    resolveLocalQueries = true;

    settings = {
      server = {
        interface = [ "127.0.0.1" ] ++ (lib.mapAttrsToList (name: net: "10.1.${toString net.id}.1") networks);
        access-control = [ "0.0.0.0/0 refuse" "127.0.0.0/8 allow" ]
          ++ (lib.mapAttrsToList (name: net: "10.1.${toString net.id}.0/24 allow") networks);

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

        so-rcvbuf = "1m"; # Safe to use now that net.core.rmem_max is elevated via sysctl

        private-domain = config.networking.domain; # allow resolving these domains to private addresses
        local-zone = [ ''"${config.networking.domain}" typetransparent'' ];
        local-data = [
          ''"tv.${config.networking.domain} IN A ${tvIp}"''
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

  # needed by sqm-cake systemd service
  boot.kernelModules = [ "ifb" ];

  # use cake to fix bufferbloat
  systemd.services.sqm-cake = {
    description = "CAKE SQM Network Shaper on WAN and Virtual Ingress IFB Interfaces";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "root";
    };

    script = ''
      # --- INGRESS (DOWNLOAD) SHAPING VIA IFB ---
      # Setup virtual intermediate interface link
      ${pkgs.iproute2}/bin/ip link add name ifb-wan type ifb || true
      ${pkgs.iproute2}/bin/ip link set dev ifb-wan up

      # Clean any old ingress redirection rules on the physical WAN port
      ${pkgs.iproute2}/bin/tc qdisc del dev ${wanInterface} ingress 2>/dev/null || true
      ${pkgs.iproute2}/bin/tc qdisc del dev ifb-wan root 2>/dev/null || true

      # Redirect incoming WAN traffic to our virtual ifb-wan interface
      ${pkgs.iproute2}/bin/tc qdisc add dev ${wanInterface} handle ffff: ingress
      ${pkgs.iproute2}/bin/tc filter add dev ${wanInterface} parent ffff: matchall \
        action mirred egress redirect dev ifb-wan

      # Apply CAKE shaper onto the virtual Ingress path (Forces Downstream Queuing)
      # Uses "dual-dsthost" to maintain fairness per home consumer device
      ${pkgs.iproute2}/bin/tc qdisc add dev ifb-wan root cake \
        bandwidth ${wanDownloadSpeed} \
        ethernet \
        besteffort \
        dual-dsthost \
        ingress

      # --- EGRESS (UPLOAD) SHAPING ON PHYSICAL WAN ---
      # Clean old egress root queuing disciplines
      ${pkgs.iproute2}/bin/tc qdisc del dev ${wanInterface} root 2>/dev/null || true

      # Apply CAKE shaper onto physical WAN Outbound
      # Enables "nat" peeling to match local clients inside the internal tracking state
      ${pkgs.iproute2}/bin/tc qdisc add dev ${wanInterface} root cake \
        bandwidth ${wanUploadSpeed} \
        ethernet \
        besteffort \
        dual-srchost \
        nat
    '';

    postStop = ''
      echo "Tearing down CAKE SQM network interfaces..."
      ${pkgs.iproute2}/bin/tc qdisc del dev ${wanInterface} root 2>/dev/null || true
      ${pkgs.iproute2}/bin/tc qdisc del dev ${wanInterface} ingress 2>/dev/null || true
      ${pkgs.iproute2}/bin/tc qdisc del dev ifb-wan root 2>/dev/null || true
      ${pkgs.iproute2}/bin/ip link set dev ifb-wan down 2>/dev/null || true
      ${pkgs.iproute2}/bin/ip link del dev ifb-wan 2>/dev/null || true
    '';
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

