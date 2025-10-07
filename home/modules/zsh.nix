{ nixosConfig, pkgs, lib, ... }:

let
  nixosConfigPath = "~/Projects/nixos-config";

in
{
  programs = {
    zsh = {
      # TODO: already enabled system wide?
      enable = true;
      defaultKeymap = "viins";
      autosuggestion.enable = true;
      enableCompletion = true;
      syntaxHighlighting.enable = true;

      sessionVariables = {
        TERM="xterm-256color";
      };

      shellAliases = {
        ls = "colorls";
        os-rebuild = "nixos-rebuild switch --flake ${nixosConfigPath}#${nixosConfig.networking.hostName}";
        fetch = "SPRITE=$(pokeget random --hide-name); HEIGHT=$(echo \"$SPRITE\" | wc -l); fastfetch --data-raw \"$SPRITE\"; echo \"$HEIGHT\""; # TODO: vertical align to sprite https://github.com/fastfetch-cli/fastfetch/issues/458
      };

      # show fetch on new terminal windows
      initContent = lib.mkOrder 1500 ''
        fetch
      '';
    };

    starship = {
      enable = true;
      settings = {};
    };
  };

  home.packages = [ pkgs.pokeget-rs ]; # TODO: use ${pkgs.pokeget-rs/bin/pokeget} in fetch alias
}
