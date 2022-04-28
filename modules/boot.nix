{ config, ... }:

{
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

#    plymouth = {
#      enable = true;
#    };
  };

  # needed for docker nvidia https://github.com/NVIDIA/nvidia-docker/issues/1447#issuecomment-836594056                                             
  systemd.enableUnifiedCgroupHierarchy = false;
}
