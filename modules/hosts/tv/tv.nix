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
      initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" ];
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
      interfaces.eno1.wakeOnLan.enable = true;
      firewall.allowedUDPPorts = [ 9 ]; # wake on LAN
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
    };

    environment = {
      persistence."${config.constants.persistentDir}".directories = [ "/home/${user}/local/share/plex" ];
      etc."ssh/ssh_host_ed25519_key.pub".source = ./ssh_host_ed25519_key.pub;
    };
  };
}
