{ inputs, ... }:

{
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "desktop";

  flake.modules.nixos.desktop = { config, lib, pkgs, ... }: {
    networking.hostName = "desktop";

    imports = with inputs.self.modules.nixos; [
      common
      graphical
      nebula
      polkit
      syncthing
    ];

    boot.initrd = {
      availableKernelModules = [ "nvme" ];
      kernelModules = [ "amdgpu" ];
    };

    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

    hardware = {
      enableAllFirmware = true;
      cpu.amd.updateMicrocode = config.hardware.enableRedistributableFirmware;
      amdgpu.initrd.enable = true;
    };

    users.users.llamacpp = {
      isSystemUser = true;
      group = "llamacpp";
      # ROCm needs /dev/dri which is gated by the video/render groups
      extraGroups = [ "video" "render" ];
    };
    users.groups.llamacpp = { };

    services.llama-cpp = {
      enable = true;
      package = pkgs.llama-cpp-rocm;
      settings = {
        models-preset = (pkgs.formats.ini { }).generate "llama-models.ini" {
          "qwen3.8" = {
            hf-repo = "unsloth/Qwen3.8-27B-GGUF";
            hf-file = "Qwen3.8-27B-UD-Q4_K_M.gguf";
            alias = "qwen3.8";
          };
        };

        gpu-layers = "-1";
        ctx-size = 64000;

        flash-attn = "on";
        cache-type-k = "q4_0";
        cache-type-v = "q4_0";

        spec-type = "draft-mtp";
        spec-draft-n-max = 2;

        ubatch-size = 512;
        batch-size = 512;

        temperature = 1.0;
        top-p = 0.95;
        top-k = 20;
        min-p = 0.05;
        repeat-penalty = 1.0;
        presence-penalty = 0.0;
      };
    };

    # persist the module's state/cache dirs across boot (impermanence)
    environment.persistence."${config.constants.persistentDir}".directories = [
      { directory = "/var/lib/llama-cpp"; user = "llamacpp"; group = "llamacpp"; }
      { directory = "/var/cache/llama-cpp"; user = "llamacpp"; group = "llamacpp"; }
    ];

    # the module hardens with a DynamicUser; ROCm needs the video/render
    # groups for /dev/dri, so run as our system user instead
    systemd.services.llama-cpp = {
      serviceConfig = {
        User = "llamacpp";
        Group = "llamacpp";
        DynamicUser = lib.mkForce false;
        # the 7900xtx is not officially supported by ROCm, point at the closest arch
        Environment = [
          "HSA_OVERRIDE_GFX_VERSION=11.0.0"
          "ROC_ENABLE_PRE_VEGA=0"
        ];
      };
    };

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
