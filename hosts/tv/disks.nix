{ disko, nixpkgs, pkgs, ... }:

# TODO: resize /nix to fill space in excess of the 6G image size as hook
# https://github.com/nix-community/disko/blob/master/docs/disko-images.md

let
  configTxt = pkgs.writeText "config.txt" ''
    [pi4]
    kernel=u-boot-rpi4.bin
    enable_gic=1

    # Otherwise the resolution will be weird in most cases, compared to
    # what the pi3 firmware does by default.
    disable_overscan=1

    # Supported in newer board revisions
    arm_boost=1

    hdmi_enable_4kp60=1

    [all]
    # Boot in 64-bit mode.
    arm_64bit=1

    # U-Boot needs this to work, regardless of whether UART is actually used or not.
    # Look in arch/arm/mach-bcm283x/Kconfig in the U-Boot tree to see if this is still
    # a requirement in the future.
    enable_uart=1

    # Prevent the firmware from smashing the framebuffer setup done by the mainline kernel
    # when attempting to show low-voltage or overtemperature warnings.
    avoid_warnings=1

    dtparam=audio=on
  '';

in {
  imports = [ disko.nixosModules.disko ];

  disko = {
    imageBuilder = {
      enableBinfmt = true;
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      kernelPackages = nixpkgs.legacyPackages.x86_64-linux.linuxPackages_latest;
    };
    devices = { 
      disk.main = {
        device = "/dev/mmcblk0"; # SD Card
        type = "disk";
        imageSize = "6G"; # this is the minimum size needed, expand the /nix partition to fill the extra space on the disk afterwards
        imageName = "raspberry-pi-tv-image";
        content = {
          type = "gpt";
          partitions = {
            firmware = {
              size = "30M";
              priority = 1;
              type = "0700";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/firmware";
                postMountHook = toString (pkgs.writeScript "postMountHook.sh" ''
                  cd ${pkgs.raspberrypifw}/share/raspberrypi/boot && cp bootcode.bin fixup*.dat start*.elf *.dtb /mnt/firmware/
                  cp ${pkgs.ubootRaspberryPi4_64bit}/u-boot.bin /mnt/firmware/u-boot-rpi4.bin
                  cp ${configTxt} /mnt/firmware/config.txt
                '');
              };
            };
            boot = {
              size = "1G";
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
  };
}

