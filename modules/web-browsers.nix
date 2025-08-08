{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.ungoogled-chromium ];

  programs.chromium = {
    enable = true;
    extensions = [
      "cjpalhdlnbpafiamejdnhcphjbkeiagm" # ublock origin
      "oboonakemofpalcgghocfoadofidjkkk" # keepassxc-browser
      "eimadpbcbfnmbkopoojfekhnkhdbieeh" # dark reader
    ];
    
    defaultSearchProviderEnabled = true;
    defaultSearchProviderSearchURL = "https://duckduckgo.com/?q={searchTerms}";
    defaultSearchProviderSuggestURL = "https://duckduckgo.com/ac/?q={searchTerms}&type=list";
  };
}

