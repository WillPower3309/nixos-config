{ config, ... }:

{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
  };

  # blutooth GUI
  services.blueman.enable = true;
}
