{ config, lib, pkgs, ... }:

{
  services.pipewire = {
    enable = true;
    jack.enable = true;
    pulse.enable = true;
    alsa.enable = true;

    # remove unneeded interfaces
    # find the device.name with `wpctl status` followed by `wpctl inspect <id>`
    wireplumber = lib.mkIf (config.networking.hostName == "desktop") {
      enable = true;
      extraConfig = {
        "51-alsa-disable"."monitor.alsa.rules" = [{
          matches = [{ "device.name" = "~alsa_card.pci-*"; }];
          actions.update-props."device.disabled" = "true";
        }];
        "52-default-output"."monitor.alsa.rules" = [{
          matches = [{ "device.name" = "alsa_card.usb-S.M.S.L_Audio_SMSL_M-3_Desktop_DAC-00"; }];
          actions.update-props."device.profile" = "pro-audio";
        }];
# TODO: need to determine profile name
#        "53-default-input"."monitor.alsa.rules" = [{
#          matches = [{ "device.name" = "alsa_card.usb-Focusrite_Scarlett_Solo_4th_Gen_S18HY203300821-00"; }];
#          actions.update-props."device.profile" = "Analog Surround 4.0 Input";
#        }];
      };
    };
  };

  environment.systemPackages = with pkgs; [
    pavucontrol
    easyeffects
  ];
}

