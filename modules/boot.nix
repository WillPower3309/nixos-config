{ config, inputs, lib, ... }:

{
  imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

  boot = {
    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
      autoGenerateKeys.enable = true;
      autoEnrollKeys = {
        enable = true;
        autoReboot = true;
      };
    };

    loader = {
      systemd-boot = {
        enable = false; # needed for lanzaboote
        editor = false; # true allows gaining root access by passing init=/bin/sh as a kernel parameter
        consoleMode = "max";

        #windows = lib.mkIf (config.networking.hostName == "desktop") {
        #  "11-home" = {
        #    title = "Windows 11 Home";
        #    efiDeviceHandle = "FS1";
        #  };
        #};
        edk2-uefi-shell.enable = true;
      };

      timeout = 0;
    };

    plymouth.enable = true;

    initrd.systemd.enable = true;

    kernelParams = [ "quiet" "udev.log_level=3" "plymouth.use-simpledrm=0" ];
    consoleLogLevel = 0;

    tmp = {
      useTmpfs = true; # true lets us configure the size below
      tmpfsSize = "50%";
    };
  };

  environment.persistence."/nix/persist".directories = [ config.boot.lanzaboote.pkiBundle ];
}

