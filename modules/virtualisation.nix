{ config, pkgs, ... }:

let

{
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu.verbatimConfig = ''
        user = "will"
        group = "kvm"

        cgroup_device_acl = [
          "/dev/null", "/dev/full", "/dev/zero",
          "/dev/random", "/dev/urandom",
          "/dev/ptmx", "/dev/kvm", "/dev/kqemu",
          "/dev/rtc","/dev/hpet",
          "/dev/input/by-id/usb-Razer_Razer_BlackWidow_Chroma-event-kbd",
          "/dev/input/by-id/usb-Logitech_USB_Receiver-if02-event-mouse",
        ]
      '';
    };
  };

  boot = {
    kernelModules = [ "kvm-intel" "vfio_virqfd" "vfio_pci" "vfio_iommu_type1" "vfio" ];
    kernelParams = [ "intel_iommu=on" ];
    blacklistedKernelModules = ["nouveau"];
    extraModprobeConfig = "options vfio-pci ids=10de:1c03,10de:10f1";
  };

  environment = {
    systemPackages = with pkgs; [
        virt-manager
        OVMF
    ];

    persistence."/nix/persist".directories = [ "/var/lib/libvirt" ];
  };
}
