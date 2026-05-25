{ inputs, ... }:

{
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "laptop";

  flake.modules.nixos.laptop = { config, ... }: {
    imports = with inputs.self.modules.nixos; [
      common
      graphical
      android-dev
      bluetooth
      nebula
      polkit # needed for sway
      power
      syncthing
      wifi
    ] ++ [ inputs.nixos-hardware.nixosModules.framework-16-7040-amd ];

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
  };
}

