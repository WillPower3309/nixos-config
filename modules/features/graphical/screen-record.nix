{
  flake.modules.nixos.screen-record = { config, pkgs, ... }: {
    environment.systemPackages = with pkgs; [ obs-studio ];

    # virtual camera and mic support
    boot = {
      extraModulePackages =  [ config.boot.kernelPackages.v4l2loopback.out ];
      kernelModules = [
        "v4l2loopback" # Virtual Camera
        "snd-aloop" # Virtual Microphone, built-in
      ];
      extraModprobeConfig = ''
        options v4l2loopback exclusive_caps=1 card_label="Virtual Camera"
      '';
    };
  };
}
