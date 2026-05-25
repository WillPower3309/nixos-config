{ inputs, lib, ... }:

{
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "tv";

  flake.modules.nixos.tv = { config, pkgs, lib, ... }: {
    imports = with inputs.self.modules.nixos; [
      common
      ssh-server
    ];

    boot = {
      lanzaboote.enable = false;
      initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" ];
      kernelParams = [
        "vt.global_cursor_default=0"
        "i915.fastboot=1"
        "i915.enable_psr=0"
        "video=efifb:off"
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

    networking = {
      hostName = "tv";
      wireless.enable = false;
      interfaces.eno1.wakeOnLan.enable = true;
      firewall.allowedUDPPorts = [ 9 ];
    };

    users = {
      users = {
        root = {
          password = "tv";
          openssh.authorizedKeys.keys = [ (builtins.readFile ../../../modules/home/id_ed25519.pub) ];
        };
        kodi = {
          isNormalUser = true;
          extraGroups = [ "video" "audio" "input" "render" "dialout" ];
        };
      };
      mutableUsers = false;
    };

    systemd.services."getty@tty2".enable = false;
    environment.systemPackages = let
      moonlight-kodi-wrapper = pkgs.writeShellScriptBin "launch-moonlight" ''
        KODI_PID=$(pidof kodi.bin)
        if [ -n "$KODI_PID" ]; then
          kill -STOP "$KODI_PID"
        fi

        export QT_QPA_PLATFORM=linuxfb
        export MOONLIGHT_HWDEC=vaapi
        export LIBVA_DRIVER_NAME=iHD

        openvt -c 2 -s -f -- ${pkgs.moonlight-qt}/bin/moonlight

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

    nixpkgs.config.kodi.enableAdvancedLauncher = true;

    services.getty.autologinUser = "kodi";
    environment.loginShellInit = let kodi-package = pkgs.kodi-gbm.withPackages(kodiPkgs: with kodiPkgs; [
      inputstream-adaptive
      joystick
    ]);
    in ''
      [[ "$(tty)" = "/dev/tty1" ]] && ${kodi-package}/bin/kodi-standalone
    '';

    environment = {
      persistence."/nix/persist".directories = [
        { directory = "/home/kodi/.kodi"; user = "kodi"; group = "users"; }
        { directory = "/home/kodi/.cache"; user = "kodi"; group = "users"; }
      ];
      etc."ssh/ssh_host_ed25519_key.pub".source = ./ssh_host_ed25519_key.pub;
    };
  };
}
