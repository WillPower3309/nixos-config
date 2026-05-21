{ config, lib, pkgs, ... }:

{
  services.pipewire = {
    enable = true;
    jack.enable = true;
    pulse.enable = true;
    alsa.enable = true;
  };
}

