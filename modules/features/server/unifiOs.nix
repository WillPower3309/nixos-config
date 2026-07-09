{ inputs, ... }:

{
  flake.modules.nixos.unifiOs = { config, lib, pkgs, ... }: let {
    package = flake.packages.${pkgs.system}.unifi-os-server;
    stateDir = "/var/lib/unifi-os-server";
    imageManifest = lib.importJSON "${package}/manifest.json";

    in {
      assertions = [
        {
          assertion = config.virtualisation.podman.enable;
          message = "services.unifi-os-server requires virtualisation.podman.enable = true.";
        }
        {
          assertion = config.virtualisation.oci-containers.backend == "podman";
          message = "services.unifi-os-server requires virtualisation.oci-containers.backend = \"podman\".";
        }
      ];

      # TODO: automatic from oci-containers config? are all needed?
      networking.firewall = {
        allowedTCPPorts = [
          11443
          8080
          8443
          6789
          8880
          8843
        ];
        allowedUDPPorts = [ 3478 10001 ];
      };

      # TODO: simplify this
      systemd.tmpfiles.rules = [
        "d ${stateDir} 0755 root root -"
      ] ++ map(subdir: "d ${stateDir}/${subdir} 0755 root root -") [
        "persistent"
        "data"
        "srv"
        "unifi"
        "mongodb"
        "log"
      ];

      systemd.services.podman-unifi-os-server = {
        restartTriggers = [ package ];

        preStart = lib.mkAfter ''
          uuid_file="${stateDir}/data/uos_uuid"
          if ! grep -qP '^[0-9a-f]{8}-[0-9a-f]{4}-5' "$uuid_file" 2>/dev/null; then
            ${pkgs.util-linux}/bin/uuidgen -s -n @dns -N "$(cat /etc/machine-id)" > "$uuid_file"
          fi
        '';
      };

      virtualisation.oci-containers.containers.unifi-os-server = {
        image = package.passthru.imageTag or (head (head imageManifest).RepoTags);
        imageFile = "${package}/image.tar";
        autoStart = true;
        privileged = true;
        # TODO: are all needed?
        ports = [
          "11443:443" # ui
          "8080:8080" # uap device inform
          "8443:8443" # controller https
          "6789:6789" # mobile speed test
          "8880:8880" # http captive portal
          "8843:8843" # https captive portal
          "3478:3478/udp" # stun
          "10001:10001/udp" # device discovery
        ];

        environment = {
          APP_MODEL = "UOSSERVER";
          APP_VERSION = package.version;
          PRODUCT_NAME = "uosserver";
          UOS_SYSTEM_IP = config.constants.loopbackAddr;
          UOS_SERVER_VERSION = package.version;
          FIRMWARE_PLATFORM = if pkgs.stdenv.hostPlatform.isAarch64 then "linux-arm64" else "linux-x64";
        };

        volumes = let
          ucorePreStartFix = pkgs.writeText "unifi-core-prestart-fix.conf" ''
            [Unit]
            Wants=unifi-os-server-fake-ntp.service
            After=unifi-os-server-fake-ntp.service

            [Service]
            ExecStartPre=-/bin/mkdir -p /data/unifi-core/config/http
          '';

          nginxPreStartFix = pkgs.writeText "nginx-prestart-fix.conf" ''
            [Service]
            ExecStartPre=-/bin/mkdir -p /var/log/nginx
          '';

          fakeNtpService = pkgs.writeText "unifi-os-server-fake-ntp.service" ''
            [Unit]
            Description=Fake NTP service for UniFi OS Server timedatectl checks

            [Service]
            Type=oneshot
            ExecStart=/bin/true
            RemainAfterExit=yes

            [Install]
            WantedBy=multi-user.target
          '';

          fakeNtpList = pkgs.writeText "unifi-os-server-fake-ntp.list" ''
            unifi-os-server-fake-ntp.service
          '';

          mongoPreStartFix = pkgs.writeText "mongodb-prestart-fix.conf" ''
            [Service]
            ExecStartPre=+/bin/bash -c "mkdir -p /var/log/mongodb && chown mongodb:mongodb /var/log/mongodb /var/lib/mongodb"
          '';
        in [
          "${stateDir}/persistent:/persistent"
          "${stateDir}/log:/var/log"
          "${stateDir}/data:/data"
          "${stateDir}/srv:/srv"
          "${stateDir}/unifi:/var/lib/unifi"
          "${stateDir}/mongodb:/var/lib/mongodb"
          "${fakeNtpService}:/etc/systemd/system/unifi-os-server-fake-ntp.service:ro"
          "${fakeNtpList}:/etc/systemd/ntp-units.d/unifi-os-server-fake-ntp.list:ro"
          "${ucorePreStartFix}:/etc/systemd/system/unifi-core.service.d/prestart-fix.conf:ro"
          "${nginxPreStartFix}:/etc/systemd/system/nginx.service.d/prestart-fix.conf:ro"
          "${mongoPreStartFix}:/etc/systemd/system/mongodb.service.d/prestart-fix.conf:ro"
        ];

        extraOptions = [
          "--systemd=always"
          "--add-host=host.docker.internal:host-gateway"
          "--pids-limit=8192"
        ];
      };
    };
  };
}
