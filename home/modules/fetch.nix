{ pkgs, ...}:

{
  home.packages = [ pkgs.pokeget-rs ];
  programs.fastfetch = {
    enable = true;
    settings = {
      logo = {
        source = "nixos_small";
        padding = {
          right = 1;
        };
    };
  };
}

