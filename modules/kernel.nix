{ config, pkgs, ... }:

{
  boot = {
#    kernelPackages = pkgs.linuxPackages_custom rec {
#      version = "5.10.37";
#      src = pkgs.fetchurl {
#        url = "mirror://kernel/linux/kernel/v5.x/linux-${version}.tar.xz";
#        sha256 = "qNXjMJ2vxITrcPlHR6bv/6KaebrmUa4SYzPpE8AL4Hc=";
#      };
#      configfile = ./kernelConfig;
#    };

    kernelPackages = pkgs.linuxPackages_xanmod;
  };
}
