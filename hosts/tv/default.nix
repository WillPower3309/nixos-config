{ pkgs, lib, nixos-hardware, impermanence, home-manager, ... }:

# TODO: remove what is already done in the nixos-hardware module
let
  hostKeyPath = /etc/ssh/ssh_host_ed25519_key;

in
{
  imports = [
    nixos-hardware.nixosModules.raspberry-pi-4
    impermanence.nixosModules.impermanence
    home-manager.nixosModules.home-manager
    ./disks.nix
    ../../modules/nix.nix
    ../../modules/sound.nix
  ];

  powerManagement.cpuFreqGovernor = "powersave";

  # Avoiding some heavy IO
  nix.settings.auto-optimise-store = false;

  boot = {
    loader = {
      generic-extlinux-compatible.enable = true;
      grub.enable = false;
    };

    # enable HDMI audio
    kernelParams = [ "snd_bcm2835.enable_hdmi=1" ];

    supportedFilesystems.zfs = lib.mkForce false;
  };

  time.timeZone = "America/Toronto";

  networking = {
    hostName = "tv";
    wireless.enable = false;
  };

  users = {
    users = {
      root = {
        password = "pi";
        openssh.authorizedKeys.keys = [ (builtins.readFile ../../home/id_ed25519.pub) ];
      };
      kodi = {
        isNormalUser = true;
        extraGroups = [ "video" "audio" "input" ]; # TODO: do I need any more groups? https://forums.raspberrypi.com/viewtopic.php?t=251645
      };
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
      path = "/nix/persist/${(toString hostKeyPath)}";
      type = "ed25519";
    }];
  };

  hardware = {
    graphics.enable = true;
    bluetooth.enable = false;
    raspberry-pi."4" = {
      i2c1.enable = true;
      fkms-3d.enable = true;
    };
  };

  # an overlay to enable raspberrypi support in libcec, and thus cec-client
  nixpkgs.overlays = [
    (self: super: { libcec = super.libcec.override { withLibraspberrypi = true; }; })
  ];

  environment.systemPackages = with pkgs; [ libcec moonlight-qt polkit ];

  # allow access to raspi cec device for video group
  services.udev.extraRules = ''
    KERNEL=="vchiq", GROUP="video", MODE="0660", TAG+="systemd", ENV{SYSTEMD_ALIAS}="/dev/vchiq"
  '';

  nixpkgs.config.kodi.enableAdvancedLauncher = true;
  systemd = {
    sockets.cec-client = {
      after = [ "dev-vchiq.device" ];
      bindsTo = [ "dev-vchiq.device" ];
      wantedBy = [ "sockets.target" ];
      socketConfig = {
        ListenFIFO = "/run/cec.fifo";
        SocketGroup = "video";
        SocketMode = "0660";
      };
    };

    # TODO: custom plugins https://discourse.nixos.org/t/how-to-add-custom-kodi-plugins-yet-another-how-to-use-a-custom-derivation-in-my-flake-post/46238
      # remove nixpkgs.config.kodi.enableAdvancedLauncher = true
    # TODO: hardening
    services = {
      kodi = let kodi-package = pkgs.kodi-gbm.withPackages(kodiPkgs: with kodiPkgs; [
        inputstream-adaptive
        youtube
        joystick
      ]);
      in {
        description = "Kodi media center";
        wantedBy = ["multi-user.target"];
        after = [
          "network-online.target"
          "sound.target"
          "systemd-user-sessions.service"
        ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          Type = "simple";
          User = "kodi";
          ExecStart = "${kodi-package}/bin/kodi-standalone";
          Restart = "always";
          TimeoutStopSec = "15s";
          TimeoutStopFailureMode = "kill";
        };
      };

      cec-client = {
        after = [ "dev-vchiq.device" ];
        bindsTo = [ "dev-vchiq.device" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          ExecStart = ''${pkgs.libcec}/bin/cec-client -d 1'';
          ExecStop = ''/bin/sh -c "echo q > /run/cec.fifo"'';
          StandardInput = "socket";
          StandardOutput = "journal";
          Restart="no";
        };
      };
    };
  };

  users.extraUsers.kodi.isNormalUser = true;

  home-manager.users.kodi = {
    nixpkgs.config.allowUnfree = true;
    home = {
      username = "kodi";
      homeDirectory = "/home/kodi";
      stateVersion = "22.05";

      file = {
        widevine-lib = {
          source = "${pkgs.widevine-cdm}/share/google/chrome/WidevineCdm/_platform_specific/linux_x64/libwidevinecdm.so";
          target = ".kodi/cdm/libwidevinecdm.so";
        };
        widevine-manifest= {
          source = "${pkgs.widevine-cdm}/share/google/chrome/WidevineCdm/manifest.json";
          target = ".kodi/cdm/manifest.json";
        };
      };
    };
  };

  environment = {
    persistence."/nix/persist" = {
      hideMounts = true;
      directories = [
        "/var/log"
        "/var/lib/nixos"
        { directory = "/home/kodi"; user = "kodi"; group = "users"; }
      ];
      files = [ (toString hostKeyPath) ];
    };
    etc."ssh/ssh_host_ed25519_key.pub".source = ./ssh_host_ed25519_key.pub;
  };

  nixpkgs.hostPlatform = "aarch64-linux"; # TODO: auto define in modules/nix.nix?
  system.stateVersion = "22.11";
}
