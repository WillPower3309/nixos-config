{ pkgs, ... }:

{
  programs.chromium = {
    enable = true;
    package = pkgs.ungoogled-chromium;
    # TODO: extensions
  };

  programs.qutebrowser = {
    enable = true;
  };

  home.persistence."/nix/persist/home/will".directories = [ ".config/chromium" ];
}
