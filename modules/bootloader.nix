{ config, ... }:

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
  };
}
