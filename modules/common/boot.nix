{ config, inputs, lib, ... }:

{
  boot = {
    lanzaboote = {
      enable = lib.mkDefault true;
      pkiBundle = "/var/lib/sbctl";
      autoGenerateKeys.enable = true;
      autoEnrollKeys = {
        enable = true;
        autoReboot = true;
      };
    };

    loader = {
      systemd-boot = {
        enable = lib.mkDefault (!config.boot.lanzaboote.enable);
        editor = false; # true allows gaining root access by passing init=/bin/sh as a kernel parameter
        consoleMode = "max";
        edk2-uefi-shell.enable = true;
      };
    };

    initrd.systemd.enable = true;

    tmp = {
      useTmpfs = true; # true lets us configure the size below
      tmpfsSize = "50%";
    };
  };

  environment.persistence."/nix/persist".directories = [ config.boot.lanzaboote.pkiBundle ];
}

