{ disko, ... }:

{
  imports = [ disko.nixosModules.disko ];

  disko.devices = {
    disk.main = {
      device = "/dev/vda"; # virtual disk
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            name = "boot";
            size = "1M";
            type = "EF02";
          };
          esp = {
            name = "ESP";
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          nix = {
            name = "root";
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/nix";
            };
          };
        };
      };
    };
    nodev."/" = {
      fsType = "tmpfs"; 
      mountOptions = [
        "size=128M"
        "defaults"
        "noatime"
        "mode=755"
      ];
    };
  };
}

