{ config, pkgs, lib, inputs, ... }:

let
  hostKeyPath = /etc/ssh/ssh_host_ed25519_key;

in
{
  imports = [
    inputs.impermanence.nixosModules.impermanence
    inputs.home-manager.nixosModules.home-manager
    ./disks.nix
    ../../modules/boot.nix
    ../../modules/nix.nix
  ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" ];
  hardware = {
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    enableAllFirmware = true;
    graphics.enable = true;
    bluetooth.enable = false;
  };

  services = {
    pulseaudio.enable = false;
    pipewire.enable = false;
  };

  time.timeZone = "America/Toronto";

  networking = {
    hostName = "tv";
    wireless.enable = false;
  };

  users = {
    users = {
      root = {
        password = "tv";
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

  environment.systemPackages = with pkgs; [ libcec moonlight-qt polkit ];

  # allow access to raspi cec device for video group
  services.udev.extraRules = ''
    KERNEL=="vchiq", GROUP="video", MODE="0660", TAG+="systemd", ENV{SYSTEMD_ALIAS}="/dev/vchiq"
  '';


  # TODO: custom plugins https://discourse.nixos.org/t/how-to-add-custom-kodi-plugins-yet-another-how-to-use-a-custom-derivation-in-my-flake-post/46238
    # remove nixpkgs.config.kodi.enableAdvancedLauncher = true
  nixpkgs.config.kodi.enableAdvancedLauncher = true;
  services.getty.autologinUser = "kodi";
  environment.loginShellInit = let kodi-package = pkgs.kodi-gbm.withPackages(kodiPkgs: with kodiPkgs; [
    inputstream-adaptive
    youtube
    joystick
  ]);
  in ''
    [[ "$(tty)" = "/dev/tty1" ]] && ${kodi-package}/bin/kodi-standalone
  '';

  # TODO: hardening
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
    services.cec-client = {
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

  users.extraUsers.kodi.isNormalUser = true;

  home-manager.users.kodi = {
    nixpkgs.config.allowUnfree = true;
    home = {
      username = "kodi";
      homeDirectory = "/home/kodi";
      stateVersion = config.system.nixos.release;

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
        { directory = "/home/kodi/.kodi"; user = "kodi"; group = "users"; }
        { directory = "/home/kodi/.cache"; user = "kodi"; group = "users"; }
      ];
      files = [ (toString hostKeyPath) ];
    };
    etc."ssh/ssh_host_ed25519_key.pub".source = ./ssh_host_ed25519_key.pub;
  };

  system.stateVersion = config.system.nixos.release;
}
