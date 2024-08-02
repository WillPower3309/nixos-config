{ config, pkgs, ... }:

{
  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    jack.enable = true;
    pulse.enable = true;
  };

  environment.systemPackages = with pkgs; [
    pavucontrol
    easyeffects
  ];
}
