{
  flake.modules.nixos.plymouth = {
    boot = {
      plymouth.enable = true;

      initrd.kernelModules = [ "simpledrm" ]; # TODO: needed?
      kernelParams = [ "quiet" "plymouth.use-simpledrm" "amdgpu.seamless=1" ];
      consoleLogLevel = 0;
      loader.timeout = 0;
    };
  };
}
