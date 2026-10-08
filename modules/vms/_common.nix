{ config, ... }:

{
  time.timeZone = "America/Toronto";
  services.getty.autologinUser = "root";
  system.stateVersion = config.system.nixos.release;

  networking.usePredictableInterfaceNames = false; # A single NIC (the usual case) is always eth0

  microvm = {
    hypervisor = "qemu";
    # TODO: https://microvm-nix.github.io/microvm.nix/shares.html#writable-nixstore-overlay
    # note: this share also makes qemu enable PCIe, which the nomad job's vfio-pci device relies on
    shares = [{
      tag = "ro-store";
      source = "/nix/store";
      mountPoint = "/nix/.ro-store";
    }];
  };
}
