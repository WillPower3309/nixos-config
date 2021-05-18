{ config, pkg, ... }:

{
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/8440905f-dbd5-462d-b039-827a895c7d8e";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/C2A2-75DA";
    fsType = "vfat";
  };

  fileSystems."/home/will/VMs" = {
    device = "/dev/sdb2";
    fsType = "ext4";
  };

  fileSystems."/home/will/VMs/SSD" = {
    device = "/dev/sdc1";
    fsType = "ext4";
  };

  swapDevices = [{
    device = "/dev/disk/by-uuid/65fbb82b-8731-47e9-8fc2-88ca73085050";
  }];
}
