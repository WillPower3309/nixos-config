{ inputs, lib, ... }:

let hostName = "htpc"; in {
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" hostName;

  flake.networks."10".reservations = [{
    ip-address = "10.1.10.9";
    hostname = hostName;
    hw-address = "54:b2:03:93:42:2e";
  }];

  flake.modules.nixos.htpc = { config, pkgs, lib, ... }: {
    imports = with inputs.self.modules.nixos; [
      common
      ssh-server
    ];

    boot = {
      lanzaboote.enable = false; # TODO: enable
      initrd = {
        availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" ];
        kernelModules = [ "i915" ];
      };
      kernelParams = [ "i915.enable_psr=0" ];
    };

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

    networking = {
      inherit hostName;
      wireless.enable = false;
    };

    users.users."${hostName}" = {
      isNormalUser = true;
      # TODO: are all of these needed?
      extraGroups = [ "video" "audio" "input" "render" "dialout" ]; # dialout needed for CEC serial device
    };

    environment.systemPackages = with pkgs; [
      plex-htpc
      # TODO: add vacuumtube (youtube tv client)
    ];

    # TODO: use plasma bigscreen or jovian (https://jovian-experiments.github.io/Jovian-NixOS/configuration.html)
    services.cage = {
      user = hostName;
      enable = true;
      program = "${pkgs.plex-htpc}/bin/plex-htpc";
      extraArguments = [ "-d" "-s" ];
    };

    # plex segfaults when xpad/8bitdo dongle resets corrupt SDL's evdev stream;
    # auto-relaunch the session instead of leaving a dead kiosk.
    systemd.services."cage-tty1".serviceConfig.Restart = "on-failure";

    # remove unusable pointer devices to prevent a cursor appearing
    services.udev.extraRules = ''
      # Pulse-Eight CEC adapter (CEC itself runs over its serial interface)
      ACTION!="remove", KERNEL=="event[0-9]*", \
        ENV{ID_VENDOR_ID}=="2548", ENV{ID_MODEL_ID}=="1002", \
        ENV{LIBINPUT_IGNORE_DEVICE}="1"

      # all rc devices: i915 CEC ("DP-1") and the Nuvoton IR transceiver
      ACTION!="remove", KERNEL=="event[0-9]*", SUBSYSTEMS=="rc", \
        ENV{LIBINPUT_IGNORE_DEVICE}="1"
    '';

    # needed for plex-htpc — bubblewrap checks permitted caps from pam_systemd's
    # PR_SET_KEEPCAPS and fails; setuid wrapper enters the setuid code path instead
    security.wrappers.bwrap = {
      setuid = true;
      owner = "root";
      group = "root";
      source = "${pkgs.bubblewrap}/bin/bwrap";
    };
    nixpkgs.overlays = [
      (final: prev: {
        bubblewrap = prev.bubblewrap.overrideAttrs (old: {
          mesonFlags = (old.mesonFlags or [ ]) ++ [ "-Dsupport_setuid=true" ];
        });
        buildFHSEnv = prev.buildFHSEnv.override {
          bubblewrap = "/run/wrappers";
        };
      })
    ];

    environment = {
      persistence."${config.constants.persistentDir}".directories = [{
        user = hostName;
        directory = "/home/${hostName}";
      }];
      etc."ssh/ssh_host_ed25519_key.pub".source = ./ssh_host_ed25519_key.pub;
    };

    # xbox controller connected via 8bitdo wireless adapter 2; plex-htpc has no
    # built-in inputmap for any of the names xpad reports through the adapter, so
    # install one into its per-user inputmap directory
    system.activationScripts.plex-htpc-inputmap.text = ''
      install -d -o ${hostName} -g users /home/${hostName}/.local/share/plex/inputmaps
      install -o ${hostName} -g users -m 0644 ${./8bitdo.json} \
        /home/${hostName}/.local/share/plex/inputmaps/8bitdo.json
    '';
  };
}
