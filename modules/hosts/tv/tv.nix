{ inputs, lib, ... }:

let user = "htpc"; in {
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "tv";

  flake.modules.nixos.tv = { config, pkgs, lib, ... }: {
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
      hostName = "tv";
      wireless.enable = false;
    };

    users.users."${user}" = {
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
      inherit user;
      enable = true;
      program = "${pkgs.plex-htpc}/bin/plex-htpc";
      extraArguments = [ "-d" "-s" ];
    };

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
        inherit user; directory = "/home/${user}";
      }];
      etc."ssh/ssh_host_ed25519_key.pub".source = ./ssh_host_ed25519_key.pub;
    };
  };
}
