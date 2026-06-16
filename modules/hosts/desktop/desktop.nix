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
      firmware = [(pkgs.runCommand "custom-firmware" {} ''
        mkdir -p $out/lib/firmware/{amdgpu,mediatek,rtl_nic}

        # AMD GPU — Radeon RX 7900 XT (Navi 31) + Raphael iGPU
        ${lib.concatStringsSep "\n" (map (g: "cp ${pkgs.linux-firmware}/lib/firmware/amdgpu/${g} $out/lib/firmware/amdgpu/") [
          "ip_discovery.bin"
          "gc_10_3_6*"   "gc_11_0_0*"
          "sdma_5_2*"    "sdma_6_0*"
          "vcn_3*"       "vcn_4_0*"
          "dcn_3_1_5*"   "dcn_3_2*"
          "psp_13_0_0*"  "smu_13_0_0*"
        ])}

        # Mediatek MT7922 WiFi + BT
        cp ${pkgs.linux-firmware}/lib/firmware/mediatek/{*MT7922*,*MT7961*} $out/lib/firmware/mediatek/

        # Realtek RTL8125 ethernet
        cp ${pkgs.linux-firmware}/lib/firmware/rtl_nic/rtl8125* $out/lib/firmware/rtl_nic/
      '')];

      cpu.amd.updateMicrocode = true;
    };

    # TODO: convert to systemd.mounts as described in https://nixos.wiki/wiki/NFS ?
    # TODO: move to photography module
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

    # find the device.name with `wpctl status` followed by `wpctl inspect <id>`
    services.pipewire.wireplumber = {
      enable = true;
      extraConfig = {
        "51-alsa-disable"."monitor.alsa.rules" = [{
          matches = [{ "device.name" = "~alsa_card.pci-*"; }];
          actions.update-props."device.disabled" = "true";
        }];
        "52-topping-profile"."monitor.alsa.rules" = [{
          matches = [{ "device.name" = "alsa_card.usb-Topping_DX5_II-00"; }];
          actions.update-props."device.profile" = "pro-audio";
        }];
        "53-topping-default"."monitor.audio.rules" = [{
          matches = [{ "node.name" = "~alsa_output.usb-Topping_DX5_II*"; }];
          actions.update-props."priority.session" = 2000;
        }];
        "54-scarlett-profile"."monitor.alsa.rules" = [{
          matches = [{ "device.name" = "alsa_card.usb-Focusrite_Scarlett_Solo_4th_Gen_S18HY203300821-00"; }];
          actions.update-props."device.profile" = "pro-audio";
        }];
      };
    };
  };
}
