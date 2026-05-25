{
  flake.modules.nixos.plymouth = {
    boot = {
      plymouth.enable = true;
      kernelParams = [ "quiet" "udev.log_level=3" "plymouth.use-simpledrm=0" ];
      consoleLogLevel = 0;
      loader.timeout = 0;
    };
  };
}
