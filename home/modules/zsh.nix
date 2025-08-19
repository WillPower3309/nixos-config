{ nixosConfig, pkgs, lib, ... }:

let
  nixosConfigPath = "~/Projects/nixos-config";
  powerlevel10kFilePath = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";

in
{
  programs.zsh = {
    # TODO: already enabled system wide?
    enable = true;

    defaultKeymap = "viins";

    autosuggestion.enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;

    initContent = lib.mkOrder 550 ''
      source ${pkgs.zsh-powerlevel10k}/${powerlevel10kFilePath}
      source ${./config/p10k.zsh}
    '';

    plugins = [{
     name = "powerlevel10k";
     src = pkgs.zsh-powerlevel10k;
     file = powerlevel10kFilePath;
    }];

    sessionVariables = {
      TERM="xterm-256color";
    };

    shellAliases = {
      ls = "colorls";
      os-rebuild = "nixos-rebuild switch --flake ${nixosConfigPath}#${nixosConfig.networking.hostName}";
    };
  };
}
