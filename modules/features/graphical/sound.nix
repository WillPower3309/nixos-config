{
  flake.modules.nixos.sound = {
    services.pipewire = {
      enable = true;
      jack.enable = true;
      pulse.enable = true;
      alsa.enable = true;
    };
  };
}
