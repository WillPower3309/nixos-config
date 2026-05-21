{ config, inputs, ... }:

{
  imports = [
    inputs.nixos-hardware.nixosModules.framework-16-7040-amd
    ./disks.nix
    ../../modules/graphical
    ../../modules/android-dev.nix
    ../../modules/bluetooth.nix
    ../../modules/nebula.nix
    ../../modules/polkit.nix # needed for sway
    ../../modules/power.nix
    ../../modules/syncthing.nix
    ../../modules/wifi.nix
  ];

  boot = {
    initrd = {
      availableKernelModules = [ "nvme" "xhci_pci" "thunderbolt" "usb_storage" "usbhid" "sd_mod" ];
      kernelModules = [ "dm-snapshot" "amdgpu" ];
    };
    kernelModules = [ "kvm-amd" ];
  };

  hardware = {
    enableAllFirmware = true;
    cpu.amd.updateMicrocode = config.hardware.enableRedistributableFirmware;
  };

  environment.etc."ssh/ssh_host_ed25519_key.pub".source = ./ssh_host_ed25519_key.pub;
}

