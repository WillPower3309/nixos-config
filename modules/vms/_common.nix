{ config, ... }:

{
  time.timeZone = "America/Toronto";
  services.getty.autologinUser = "root";
  system.stateVersion = config.system.nixos.release;

  # the only NIC is the SR-IOV VF passed through by the nomad job (see modules/features/nomad.nix), so it's always
  # eth0. Set networking.interfaces.eth0.macAddress for a stable MAC (the host leaves it unset so the guest can)
  networking.usePredictableInterfaceNames = false;

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
