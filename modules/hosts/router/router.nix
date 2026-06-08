{ inputs, lib, ... }:

# TODO: prometheus and grafana, map Prometheus metrics collection exporters to trace live CAKE drop rates and queue latencies onto Grafana
let
  authorizedKey = builtins.readFile ../../features/ssh-client/id_ed25519.pub;

  wanInterface = "wan0";
  lanInterface = "lan0";

  # should be 90-95% of the true limit (needed for cake)
  wanBandwidth = "900M";

  networks = inputs.self.networks;

  allReservations = lib.pipe networks [
    (networks: lib.mapAttrsToList (_: net: net.dhcp.reservations) networks)
    (reservations: lib.lists.flatten reservations)
  ];

in {
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "router";

  flake.modules.nixos.router = { config, pkgs, lib, ... }: {
    networking.hostName = "router";

    imports = with inputs.self.modules.nixos; [
      common
      ssh-server
    ] ++ [ inputs.agenix.nixosModules.age ];

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

        # deny martian packets
        "net.ipv4.conf.default.rp_filter" = 1;
        "net.ipv4.conf.all.rp_filter" = 1;

        # On WAN, allow IPv6 autoconfiguration and tempory address use.
        "net.ipv6.conf.${wanInterface}.accept_ra" = 2;
        "net.ipv6.conf.${wanInterface}.autoconf" = 1;

        # Softirq budget tuning — CAKE + IFB ingress adds per-packet overhead
        "net.core.netdev_budget" = 600;         # default 300
        "net.core.netdev_budget_usecs" = 8000;  # default 2000

        # RPS flow table — spreads RX processing across CPUs
        "net.core.rps_sock_flow_entries" = 32768;
      };
    };

    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="60:be:b4:00:85:28", NAME="${wanInterface}"
      ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="60:be:b4:00:85:29", NAME="${lanInterface}"
      ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="60:be:b4:00:85:2a", NAME="opt0"
      ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="60:be:b4:00:85:2b", NAME="opt1"
    '';

    systemd.network = {
      enable = true;
      wait-online = {
        enable = true;
        anyInterface = false;
        extraArgs = [ "-i" "${wanInterface}" ];
      };

      netdevs = (lib.mapAttrs' (name: net: lib.nameValuePair "30-vlan${toString net.id}" {
        netdevConfig = {
          Kind = "vlan";
          Name = "${lanInterface}.${toString net.id}";
        };
        vlanConfig.Id = net.id;
      }) networks) // {
        "40-ifb-wan" = {
          netdevConfig = {
            Kind = "ifb";
            Name = "ifb-wan";
          };
        };
      };

      networks = {
        "10-${wanInterface}" = {
          matchConfig.Name = wanInterface;
          networkConfig = {
            DHCP = "ipv4";
            IPv6PrivacyExtensions = "no";
          };
          linkConfig.RequiredForOnline = "yes";
          qdiscConfig.Parent = "ingress";
          cakeConfig = {
            Bandwidth = wanBandwidth;
            PriorityQueueingPreset = "besteffort";
            FlowIsolationMode = "dual-src-host";
            NAT = true;
          };
        };

        "20-${lanInterface}" = {
          matchConfig.Name = lanInterface;
          networkConfig = {
            VLAN = lib.mapAttrsToList (name: net: "${lanInterface}.${toString net.id}") networks;
            ConfigureWithoutCarrier = true;
          };
          linkConfig.RequiredForOnline = "no";
        };

        "50-ifb-${wanInterface}" = {
          matchConfig.Name = "ifb-wan";
          linkConfig.RequiredForOnline = "no";
          cakeConfig = {
            Bandwidth = wanBandwidth;
            PriorityQueueingPreset = "besteffort";
            FlowIsolationMode = "dual-dst-host";
          };
        };
      } // (lib.mapAttrs' (name: net: lib.nameValuePair "25-vlan${toString net.id}" {
        matchConfig.Name = "${lanInterface}.${toString net.id}";
        networkConfig.Address = "10.1.${toString net.id}.1/24";
        linkConfig.RequiredForOnline = "no";
      }) networks);
    };

    boot.kernelModules = [ "ifb" ];

    # use cake to fix bufferbloat
    # systemd.network above handles: ifb-wan device, ingress qdisc on wan0, CAKE on both interfaces
    # This service only adds the tc filter to redirect ingress traffic from wan0 -> ifb-wan
    # CAKE man page: "In Linux, ingress shaping is performed on the ifb device."
    systemd.services.sqm-cake = {
      description = "CAKE SQM — Ingress redirect filter";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "root";
      };

      script = ''
        # Spread RX processing across all CPUs so CAKE doesn't bottleneck on one core
        ncpus=$(${pkgs.coreutils}/bin/nproc)
        mask=$(${pkgs.coreutils}/bin/printf '%x' "$((2**ncpus - 1))")
        for q in /sys/class/net/${wanInterface}/queues/rx-*/rps_cpus; do
          echo "$mask" > "$q" 2>/dev/null || true
        done
        for q in /sys/class/net/${wanInterface}/queues/rx-*/rps_flow_cnt; do
          echo 32768 > "$q" 2>/dev/null || true
        done

        # Redirect wan0 ingress to ifb-wan where CAKE (declared in systemd.network) shapes it
        ${pkgs.iproute2}/bin/tc filter replace dev ${wanInterface} parent ffff: matchall \
          action mirred egress redirect dev ifb-wan || true
      '';

      postStop = ''
        ${pkgs.iproute2}/bin/tc filter del dev ${wanInterface} parent ffff: 2>/dev/null || true
      '';
    };

    networking = {
      usePredictableInterfaceNames = false; # set interface names via services.udev.extraRules above
      useDHCP = false; # define per interface instead
      networkmanager.enable = lib.mkForce false;
      firewall.enable = false; # use nftables instead

      # TODO: read https://www.mankier.com/8/nft
      # TODO: from above, make sure I know what the following are: address families, hooks, tables, chains, rules, and sets
      # TODO: make this dynamic
      nftables = {
        enable = true;
        ruleset = ''
          table ip filter {
            chain input {
              type filter hook input priority 0; policy drop;

              iifname "${lanInterface}.${toString networks.trusted.id}" accept comment "Allow trusted local network to access the router"
              # TODO: we let local access router above -  should I remove the above and also allow trusted to use dhcp and dns ports below?
              iifname "${lanInterface}.${toString networks.trusted.id}" tcp dport 22 accept comment "Allow trusted local network to SSH to router"

              iifname "${lanInterface}.${toString networks.guest.id}" udp dport { ${toString config.services.unbound.settings.server.port}, 67 } accept comment "Allow guest DNS, DHCP"
              iifname "${lanInterface}.${toString networks.guest.id}" tcp dport ${toString config.services.unbound.settings.server.port} accept comment "Allow guest DNS over TCP"

              iifname "${wanInterface}" ct state { established, related } accept comment "Allow established traffic"
              iifname "${wanInterface}" icmp type { echo-request, destination-unreachable, time-exceeded } counter accept comment "Allow select ICMP"
              iifname "${wanInterface}" counter drop comment "Drop all other unsolicited traffic from wan"

              iifname "lo" accept comment "allow loopback"
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
          interface = [ config.constants.loopbackAddr ] ++ (lib.mapAttrsToList (_: net: "10.1.${toString net.id}.1") networks);
          access-control = [ "0.0.0.0/0 refuse" "127.0.0.0/8 allow" ]
            ++ (lib.mapAttrsToList (_: net: "10.1.${toString net.id}.0/24 allow") (lib.filterAttrs (_: net: net.dns) networks));

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

          local-zone = [
            "${config.networking.domain} typetransparent"
          ] ++ map (reservation: "${reservation.hostname}.${config.networking.domain} redirect") allReservations;

          local-data = [
            ''"router.${config.networking.domain} IN A 10.1.10.1"''
          ] ++ map (reservation:
            ''"${reservation.hostname}.${config.networking.domain} IN A ${reservation.ip-address}"''
          ) allReservations;
        };

        forward-zone = [{
          name = ".";
          forward-first = false;
          forward-tls-upstream = true;
          forward-addr = [
            "194.242.2.6@853#family.dns.mullvad.net"
            "194.242.2.4@853#base.dns.mullvad.net"
          ];
        }];
      };
    };

    environment.etc."ssh/ssh_host_ed25519_key.pub".source = ./ssh_host_ed25519_key.pub;
  };
}
