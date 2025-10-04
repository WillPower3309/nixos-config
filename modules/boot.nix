{
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        editor = false; # true allows gaining root access by passing init=/bin/sh as a kernel parameter
        consoleMode = "max";
      };

      timeout = 0;
    };

    plymouth.enable = true;

    initrd.systemd.enable = true;

    kernelParams = [ "quiet" "udev.log_level=3" ];
    consoleLogLevel = 0;

    tmp = {
      useTmpfs = true; # true lets us configure the size below
      tmpfsSize = "50%";
    };
  };
}
