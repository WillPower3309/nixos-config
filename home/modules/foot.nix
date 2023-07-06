{ pkgs, ... }:

{
  programs.foot.enable = true;
  # TODO: server.enable

  home.file.".config/foot/foot.ini".source =  ./config/foot/foot.ini;
}
