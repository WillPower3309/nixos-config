{ pkgs, ... }:

{
  home = {
    packages = with pkgs; [
      darktable
      gimp
      imagemagick
      vkdt
    ];

    # TODO: Store on nas
    # TODO: module
    persistence."/nix/persist".files = [
      ".config/darktable/data.db"
      ".config/darktable/library.db"
      ".config/darktable/darktablerc"
    ];
  };

  xdg.configFile."default-darkroom.i-raw".text = ''
    module:i-raw:main:43:400
    module:denoise:01:218:400
    module:hilite:01:393:400
    module:demosaic:01:568:400
    module:colour:01:931:400
    module:filmcurv:01:1094:400
    module:llap:01:1269:400
    module:hist:01:1418:634
    module:zones:01:219:800
    module:crop:01:743:400
    module:lens:01:568:800
    module:pick:01:43:800
    module:display:hist:1600:634
    module:display:main:1545:400
    module:display:dspy:0:0
    connect:i-raw:main:output:denoise:01:input
    connect:denoise:01:output:hilite:01:input
    connect:hilite:01:output:demosaic:01:input
    connect:crop:01:output:colour:01:input
    connect:colour:01:output:filmcurv:01:input
    connect:filmcurv:01:output:llap:01:input
    connect:llap:01:output:hist:01:input
    connect:demosaic:01:output:crop:01:input
    connect:hist:01:output:display:hist:input
    connect:llap:01:output:display:main:input
    connect:filmcurv:01:dspy:display:dspy:input
  '';
}

