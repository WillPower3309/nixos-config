{ config, ... }:

{
  imports = [
    ./disks.nix
    ../../modules/graphical
    ../../modules/nebula.nix
    ../../modules/polkit.nix # needed for sway
    ../../modules/syncthing.nix
  ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "amdgpu" ];

  hardware = {
    enableAllFirmware = true;
    cpu.amd.updateMicrocode = config.hardware.enableRedistributableFirmware;
  };

  # TODO: convert to systemd.mounts as described in https://nixos.wiki/wiki/NFS ?
  # TODO: move to photography module
  fileSystems."/mnt/photos" = {
    device = "10.1.10.6:/photos";
    fsType = "nfs";
    # lazy mount, disconnect after 10 minutes
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600" ];
  };

  fileSystems."/mnt/music" = {
    device = "10.1.10.6:/music";
    fsType = "nfs";
    # lazy mount, disconnect after 10 minutes
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600" ];
  };

  environment.etc."ssh/ssh_host_ed25519_key.pub".source = ./ssh_host_ed25519_key.pub;

  # find the device.name with `wpctl status` followed by `wpctl inspect <id>`
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
}

