{ config, pkgs, ... }:

{
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;

    loader = {
      systemd-boot.enable = true;
      #timeout = 0;
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

    kernelParams = [ "intel_iommu=on" ];
    blacklistedKernelModules = ["nouveau"];
    kernelModules = [ "kvm-intel" "vfio_virqfd" "vfio_pci" "vfio_iommu_type1" "vfio" ];

    extraModprobeConfig = "options vfio-pci ids=10de:1c03,10de:10f1";
  };
}
