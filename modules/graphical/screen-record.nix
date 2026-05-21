{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ obs-studio ];

  # virtual camera and mic support
  boot = {
    extraModulePackages = with config.boot.kernelPackages; [
      v4l2loopback.out
    ];

    kernelModules = [
      # Virtual Camera
      "v4l2loopback"
      # Virtual Microphone, built-in
      "snd-aloop"
    ];

    # exclusive_caps: Skype, Zoom, Teams etc. will only show device when actually streaming
    # card_label: Name of virtual camera, how it'll show up in Skype, Zoom, Teams
    # https://github.com/umlaeute/v4l2loopback
    extraModprobeConfig = ''
      options v4l2loopback exclusive_caps=1 card_label="Virtual Camera"
    '';
  };
}
