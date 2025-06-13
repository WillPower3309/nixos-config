{ pkgs, ... }:

{
  programs.chromium = {
    enable = true;
    package = pkgs.ungoogled-chromium;
    # TODO: these don't seem to work
    extensions = [
      { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # ublock origin
      { id = "oboonakemofpalcgghocfoadofidjkkk"; } # keepassxc-browser
      { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; } # dark reader
    ];
  };

  programs.qutebrowser = {
    enable = true;
  };

  home = {
    persistence."/nix/persist/home/will" = {
      files = [ ".config/chromium/Default/Preferences" ];
    };
    file.".config/chromium/First Run" = {
      text = "";
      recursive = true;
    };
  };
}

