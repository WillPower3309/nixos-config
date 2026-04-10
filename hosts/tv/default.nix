# TODO:
# - hardware acceleration for interstellar
# - wake on USB
# - proper CEC turn on / off and switch back from switch 2

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

  boot = {
    initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" ];
    kernelParams = [
      "vt.global_cursor_default=0"  # disable VT switching flicker
      "i915.fastboot=1" # prevent unnecessary mode-sets that cause flickering
      "i915.enable_psr=0"  # disable Panel Self Refresh (causes flicker on linux)
      "video=efifb:off" # disable the EFI framebuffer to let the driver take over fully
    ];
  };

  services.udev.packages = [ pkgs.game-devices-udev-rules ];

  hardware = {
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    enableAllFirmware = true;
    bluetooth.enable = false;

    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        libva
        libva-utils
      ];
    };
  };
  powerManagement.cpuFreqGovernor = "powersave";

  services = {
    pulseaudio.enable = false;
    pipewire.enable = false;
  };

  time.timeZone = "America/Toronto";

  networking = {
    hostName = "tv";
    wireless.enable = false;
    interfaces.eno1.wakeOnLan.enable = true;
    firewall.allowedUDPPorts = [ 9 ]; # wake on LAN port
  };

  users = {
    users = {
      root = {
        password = "tv";
        openssh.authorizedKeys.keys = [ (builtins.readFile ../../home/id_ed25519.pub) ];
      };
      kodi = {
        isNormalUser = true;
        extraGroups = [ "video" "audio" "input" "render" "dialout" ]; # dialout needed for CEC serial device
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

  # script to start moonlight on tty2
  systemd.services."getty@tty2".enable = false; # prevent login prompts from interfering
  environment.systemPackages = let
    moonlight-kodi-wrapper = pkgs.writeShellScriptBin "launch-moonlight" ''
      KODI_PID=$(pidof kodi.bin)
      if [ -n "$KODI_PID" ]; then
        kill -STOP "$KODI_PID"
      fi

      export QT_QPA_PLATFORM=linuxfb
      export MOONLIGHT_HWDEC=vaapi
      export LIBVA_DRIVER_NAME=iHD

      # Run Moonlight on tty2 using openvt
      openvt -c 2 -s -f -- ${pkgs.moonlight-qt}/bin/moonlight

      # When it exits, return to Kodi on tty1
      chvt 1
      if [ -n "$KODI_PID" ]; then
        kill -CONT "$KODI_PID"
      fi
    '';
  in [ moonlight-kodi-wrapper pkgs.libcec pkgs.polkit ];
  environment.variables = {
    ML_AUDIO = "sdl";
    SDL_AUDIODRIVER = "alsa";
  };
  security.wrappers.chvt = {
    source = "${pkgs.kbd}/bin/chvt";
    owner = "root";
    group = "root";
    setuid = true;
  };

  # TODO: custom plugins https://discourse.nixos.org/t/how-to-add-custom-kodi-plugins-yet-another-how-to-use-a-custom-derivation-in-my-flake-post/46238
    # remove nixpkgs.config.kodi.enableAdvancedLauncher = true
    # https://github.com/jurialmunkey/skin.arctic.fuse.3
    # https://github.com/croneter/PlexKodiConnect
  nixpkgs.config.kodi.enableAdvancedLauncher = true;

  services.getty.autologinUser = "kodi";
  environment.loginShellInit = let kodi-package = pkgs.kodi-gbm.withPackages(kodiPkgs: with kodiPkgs; [
    inputstream-adaptive
    joystick
  ]);
  in ''
    [[ "$(tty)" = "/dev/tty1" ]] && ${kodi-package}/bin/kodi-standalone
  '';

  #home-manager.users.kodi = {
  #  programs.home-manager.enable = true;

  #  home = {
  #    username = "kodi";
  #    homeDirectory = "/home/kodi";
  #    stateVersion = config.system.nixos.release;

  #    file = {
  #      widevine-lib = {
  #        source = "${pkgs.widevine-cdm}/share/google/chrome/WidevineCdm/_platform_specific/linux_x64/libwidevinecdm.so";
  #        target = ".kodi/cdm/libwidevinecdm.so";
  #      };
  #      widevine-manifest = {
  #        source = "${pkgs.widevine-cdm}/share/google/chrome/WidevineCdm/manifest.json";
  #        target = ".kodi/cdm/manifest.json";
  #      };
  #    };
  #  };
  #};

  environment = {
    persistence."/nix/persist" = {
      hideMounts = true;
      directories = [
        "/var/log"
        "/var/lib/nixos"
        # TODO: add below to HM
        { directory = "/home/kodi/.kodi"; user = "kodi"; group = "users"; }
        { directory = "/home/kodi/.cache"; user = "kodi"; group = "users"; }
      ];
      files = [ (toString hostKeyPath) ];
    };
    etc."ssh/ssh_host_ed25519_key.pub".source = ./ssh_host_ed25519_key.pub;
  };

  system.stateVersion = config.system.nixos.release;
}
