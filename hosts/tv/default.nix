{ pkgs, lib, nixos-hardware, impermanence, ... }:

# TODO: remove what is already done in the nixos-hardware module
let
  hostKeyPath = /etc/ssh/ssh_host_ed25519_key;

in
{
  imports = [
    nixos-hardware.nixosModules.raspberry-pi-4
    impermanence.nixosModules.impermanence
    ./disks.nix
    ../../modules/nix.nix
    ../../modules/sound.nix
  ];

  #powerManagement.cpuFreqGovernor = "powersave";

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

  # TODO: use keys like server - turn into ssh-server module?
  users = {
    users = {
      root = {
        password = "pi";
        openssh.authorizedKeys.keys = [ (builtins.readFile ../../home/id_ed25519.pub) ];
      };
      kodi.extraGroups = [ "video" ]; # TODO: do I need any more groups? https://forums.raspberrypi.com/viewtopic.php?t=251645
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

  environment.systemPackages = with pkgs; [ libcec ];

  # allow access to raspi cec device for video group
  services.udev.extraRules = ''
    KERNEL=="vchiq", GROUP="video", MODE="0660", TAG+="systemd", ENV{SYSTEMD_ALIAS}="/dev/vchiq"
  '';

  systemd.sockets."cec-client" = {
    after = [ "dev-vchiq.device" ];
    bindsTo = [ "dev-vchiq.device" ];
    wantedBy = [ "sockets.target" ];
    socketConfig = {
      ListenFIFO = "/run/cec.fifo";
      SocketGroup = "video";
      SocketMode = "0660";
    };
  };
  systemd.services."cec-client" = {
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

  # Kodi
  # TODO: widevine CDM and plugins: https://nixos.wiki/wiki/Kodi
  nixpkgs.config.kodi.enableAdvancedLauncher = true;
  users.extraUsers.kodi.isNormalUser = true;
  services.cage = {
    user = "kodi";
    program = "${pkgs.kodi-wayland}/bin/kodi-standalone";
    enable = true;
    environment = { WLR_LIBINPUT_NO_DEVICES = "1"; }; # use tv remote instead of input device
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
