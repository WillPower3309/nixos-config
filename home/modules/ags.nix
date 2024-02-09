{ pkgs, ... }:

{
  programs.ags = {
    enable = true;
    configDir = ./config/ags;

    # additional packages to add to the runtime
    extraPackages = with pkgs; [];
  };
}
