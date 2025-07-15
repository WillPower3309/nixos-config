{
  programs.chromium = {
    enable = true;
    extensions = [
      { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # ublock origin
      { id = "oboonakemofpalcgghocfoadofidjkkk"; } # keepassxc-browser
      { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; } # dark reader
    ];
    
    defaultSearchProviderEnabled = true;
    defaultSearchProviderSearchUrl = "https://duckduckgo.com/?q={searchTerms}";
    defaultSearchProviderSuggestUrl = "https://duckduckgo.com/ac/?q={searchTerms}&type=list";
  };
}

