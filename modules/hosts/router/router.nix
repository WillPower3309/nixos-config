{ inputs, lib, ... }:

# TODO: set up reverse DNS pointer records (PTR) in unbound so devices can be recognized via hostname instead of IP
# TODO: prometheus and grafana, map Prometheus metrics collection exporters to trace live CAKE drop rates and queue latencies onto Grafana
let
  authorizedKey = builtins.readFile ../../features/ssh-client/id_ed25519.pub;

  wanInterface = "wan0";
  lanInterface = "lan0";

  # should be 90-95% of the true limit (needed for cake)
  wanDownloadSpeed = "900mbit";
  wanUploadSpeed = "900mbit";

  networks = {
    trusted = {
      id = 10;
      dhcp = {
        enable = true;
        reservations = [
          { ip-address = "10.1.10.5"; hw-address = "f8:27:2e:0c:02:ef"; hostname = "access-point"; }
          { ip-address = "10.1.10.6"; hw-address = "9c:6b:00:19:ed:ff"; hostname = "server"; }
          { ip-address = "10.1.10.7"; hw-address = "b8:27:eb:cd:8e:3a"; hostname = "home-assistant"; }
          { ip-address = "10.1.10.8"; hw-address = "04:7c:16:76:a9:9c"; hostname = "desktop"; }
          { ip-address = "10.1.10.9"; hw-address = "54:b2:03:93:42:2e"; hostname = "tv"; }
          { ip-address = "10.1.10.10"; hw-address = "c0:f5:35:f4:95:bd"; hostname = "3d-printer"; }
        ];
      };
    };
    guest = {
      id = 20;
      dhcp = { enable = true; reservations = []; };
    };
    iot = {
      id = 30;
      dhcp = { enable = true; reservations = []; };
    };
    # TODO: this won't be needed once meshcentral and router are moved to proxmox
    management = {
      id = 100;
      dhcp = { enable = false; reservations = []; };
    };
  };

in {
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "router";

  flake.modules.nixos.router = { config, pkgs, lib, ... }: {
    networking.hostName = "router";

    imports = with inputs.self.modules.nixos; [
      common
      ssh-server
    ] ++ [ inputs.agenix.nixosModules.age ];

    age.secrets.hashedRootPassword.file = "${inputs.secrets}/hashedRootPassword.age";

    users = {
      users.root = {
        hashedPasswordFile = config.age.secrets.hashedRootPassword.path;
        openssh.authorizedKeys.keys = [ authorizedKey ];
      };
      mutableUsers = false;
    };

    powerManagement.cpuFreqGovernor = "powersave";

    hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

    boot = {
      lanzaboote.enable = false; # TODO: enable
      initrd.availableKernelModules = [ "ahci" "xhci_pci" "usbhid" "usb_storage" "sd_mod" ];
      kernel.sysctl = {
        "net.ipv4.conf.all.forwarding" = 1;

        # not using IPv6 yet
        "net.ipv6.conf.all.forwarding" = 0;
        "net.ipv6.conf.all.accept_ra" = 0;
        "net.ipv6.conf.all.autoconf" = 0;
        "net.ipv6.conf.all.use_tempaddr" = 0;

        "net.core.rmem_max" = 1048576; # Fix Unbound socket receive buffer warnings safely
        "net.ipv4.ip_nonlocal_bind" = 1; # Allow applications to bind to any IP address without waiting for the interface link to be up

        # deny martian packets TODO: once DNS is set up properly (otherwise this breaks nebula)
        #"net.ipv4.conf.default.rp_filter" = 1;
        #"net.ipv4.conf.all.rp_filter" = 1;

        # On WAN, allow IPv6 autoconfiguration and tempory address use.
        "net.ipv6.conf.${wanInterface}.accept_ra" = 2;
        "net.ipv6.conf.${wanInterface}.autoconf" = 1;
      };
    };

    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="60:be:b4:00:85:28", NAME="${wanInterface}"
      ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="60:be:b4:00:85:29", NAME="${lanInterface}"
      ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="60:be:b4:00:85:2a", NAME="opt0"
      ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="60:be:b4:00:85:2b", NAME="opt1"
    '';

    networking = {
      usePredictableInterfaceNames = false; # set interface names via services.udev.extraRules above
      useDHCP = false; # define per interface instead
      networkmanager.enable = lib.mkForce false;
      firewall.enable = false; # use nftables instead

      # TODO: read https://www.mankier.com/8/nft
      # TODO: from above, make sure I know what the following are: address families, hooks, tables, chains, rules, and sets
      # TODO: add iot rules
      nftables = {
        enable = true;
        ruleset = ''
          table ip filter {
            chain input {
              type filter hook input priority 0; policy drop;

              iifname "${lanInterface}.${toString networks.trusted.id}" accept comment "Allow trusted local network to access the router"

              iifname "${lanInterface}.${toString networks.guest.id}" udp dport { 53, 67 } accept comment "Allow guest DNS, DHCP"
              iifname "${lanInterface}.${toString networks.guest.id}" tcp dport 53 accept comment "Allow guest DNS over TCP"

              iifname "${wanInterface}" ct state { established, related } accept comment "Allow established traffic"
              iifname "${wanInterface}" icmp type { echo-request, destination-unreachable, time-exceeded } counter accept comment "Allow select ICMP"
              iifname "${wanInterface}" counter drop comment "Drop all other unsolicited traffic from wan"
              iifname "lo" accept comment "allow loopback"
              tcp dport 22 accept comment "allow ssh"
            }

            chain forward {
              type filter hook forward priority 0; policy drop;

              iifname { "${lanInterface}.${toString networks.trusted.id}", "${lanInterface}.${toString networks.guest.id}" } oifname { "${wanInterface}" } accept comment "Allow LANs to WAN"
              iifname { "${wanInterface}" } oifname { "${lanInterface}.${toString networks.trusted.id}", "${lanInterface}.${toString networks.guest.id}" } ct state { established, related } accept comment "Allow established back to LANs"

              iifname { "${lanInterface}.${toString networks.trusted.id}" } oifname { "${lanInterface}.${toString networks.management.id}" } counter accept comment "Allow trusted to management"
              iifname { "${lanInterface}.${toString networks.management.id}" } oifname { "${lanInterface}.${toString networks.trusted.id}" } ct state { established, related } counter accept comment "Allow established & related back to trusted"
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
      }) networks;

      networks = {
        "10-wan" = {
          matchConfig.Name = wanInterface;
          networkConfig = {
            DHCP = "ipv4";
            IPv6PrivacyExtensions = "no";
          };
          linkConfig.RequiredForOnline = "yes";
        };

        "20-lan0" = {
          matchConfig.Name = lanInterface;
          networkConfig = {
            VLAN = lib.mapAttrsToList (name: net: "${lanInterface}.${toString net.id}") networks;
            ConfigureWithoutCarrier = true;
          };
          linkConfig.RequiredForOnline = "no";
        };
      } // (lib.mapAttrs' (name: net: lib.nameValuePair "25-vlan${toString net.id}" {
        matchConfig.Name = "${lanInterface}.${toString net.id}";
        networkConfig.Address = "10.1.${toString net.id}.1/24";
        linkConfig.RequiredForOnline = "no";
      }) networks);
    };

    services.kea.dhcp4 = {
      enable = true;
      settings = {
        interfaces-config = {
          interfaces = lib.mapAttrsToList (name: net: "${lanInterface}.${toString net.id}") (lib.filterAttrs (name: net: net.dhcp.enable) networks);
          re-detect = true; # actively re-detect interfaces if they are re-created by networkd
          dhcp-socket-type = "raw"; # capture packets at the link-layer, surviving interface toggles
        };

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
          interface = [ config.constants.loopbackAddr ] ++ (lib.mapAttrsToList (name: net: "10.1.${toString net.id}.1") networks);
          access-control = [ "0.0.0.0/0 refuse" "127.0.0.0/8 allow" ]
            ++ (lib.mapAttrsToList (name: net: "10.1.${toString net.id}.0/24 allow") networks);

          port = 53;
          hide-identity = true;
          hide-version = true;
          qname-minimisation = true;

          harden-glue = true;
          harden-dnssec-stripped = true;
          use-caps-for-id = false;
          prefetch = true;
          edns-buffer-size = 1232;

          ip-freebind = true;
          so-reuseport = true;
          so-rcvbuf = "1m"; # Safe to use with net.core.rmem_max elevated via sysctl

          private-domain = config.networking.domain;
          local-zone = [ ''"${config.networking.domain}" typetransparent'' ];
          local-data = [
            # TODO: iterate through network dhcp reservations (or should I set based on hostname automatically?)
            ''"tv.${config.networking.domain} IN A 10.1.10.9"''
          ];
        };

        forward-zone = [{
          name = ".";

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

    boot.kernelModules = [ "ifb" ];

    # use cake to fix bufferbloat
    # TODO: download speed is cut in half?
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
        ${pkgs.iproute2}/bin/ip link add name ifb-wan type ifb || true
        ${pkgs.iproute2}/bin/ip link set dev ifb-wan up

        ${pkgs.iproute2}/bin/tc qdisc del dev ${wanInterface} ingress 2>/dev/null || true
        ${pkgs.iproute2}/bin/tc qdisc del dev ifb-wan root 2>/dev/null || true

        ${pkgs.iproute2}/bin/tc qdisc add dev ${wanInterface} handle ffff: ingress
        ${pkgs.iproute2}/bin/tc filter add dev ${wanInterface} parent ffff: matchall \
          action mirred egress redirect dev ifb-wan

        ${pkgs.iproute2}/bin/tc qdisc add dev ifb-wan root cake \
          bandwidth ${wanDownloadSpeed} \
          ethernet \
          besteffort \
          dual-dsthost \
          ingress

        ${pkgs.iproute2}/bin/tc qdisc del dev ${wanInterface} root 2>/dev/null || true

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

    environment.etc."ssh/ssh_host_ed25519_key.pub".source = ./ssh_host_ed25519_key.pub;
  };
}
