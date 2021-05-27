{ config, pkgs, ... }:

{
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;

    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    initrd = {
      luks.devices = {
        root = {
          device = "/dev/sda2";
          preLVM = true;
        };
      };

      availableKernelModules = [ "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
      kernelModules = [ "dm-snapshot" ];
    };

    kernelModules = [ "kvm-intel" "vfio_virqfd" "vfio_pci" "vfio_iommu_type1" "vfio" ];
    kernelParams = [ "intel_iommu=on" ];
    blacklistedKernelModules = ["nouveau"];

    extraModprobeConfig = "options vfio-pci ids=10de:1c03,10de:10f1";
  };
}
