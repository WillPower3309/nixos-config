{ inputs, ... }:

{
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "desktop";

  flake.modules.nixos.desktop = { config, pkgs, lib, ... }: {
    networking.hostName = "desktop";

    imports = with inputs.self.modules.nixos; [
      common
      graphical
      nebula
      polkit
      syncthing
    ];

    boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "amdgpu" ];

    hardware = {
      enableAllFirmware = true;
      cpu.amd.updateMicrocode = config.hardware.enableRedistributableFirmware;
    };

    fileSystems."/mnt/photos" = {
      device = "10.1.10.6:/photos";
      fsType = "nfs";
      options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600" ];
    };

    fileSystems."/mnt/music" = {
      device = "10.1.10.6:/music";
      fsType = "nfs";
      options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600" ];
    };

    environment.etc."ssh/ssh_host_ed25519_key.pub".source = ./ssh_host_ed25519_key.pub;

    # TODO: DX5 as default output - sometimes scarlett solo takes the output
    services.pipewire.wireplumber = {
      enable = true;
      extraConfig = {
        "51-alsa-disable"."monitor.alsa.rules" = [{
          matches = [{ "device.name" = "~alsa_card.pci-*"; }];
          actions.update-props."device.disabled" = "true";
        }];
        "52-default-output"."monitor.alsa.rules" = [{
          matches = [{ "device.name" = "alsa_card.usb-Topping_DX5_II-00"; }];
          actions.update-props."device.profile" = "pro-audio";
        }];
        "53-default-input"."monitor.alsa.rules" = [{
          matches = [{ "device.name" = "alsa_card.usb-Focusrite_Scarlett_Solo_4th_Gen_S18HY203300821-00"; }];
          actions.update-props."device.profile" = "pro-audio";
        }];
      };
    };
  };
}
