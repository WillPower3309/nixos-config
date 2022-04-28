{ pkgs, lib, ... }:
{
  programs.zsh = {
    enable = true;

    defaultKeymap = "viins";

    enableAutosuggestions = true;
    enableCompletion = true;

    initExtraBeforeCompInit = ''
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
    '';
    initExtra = ''
      source ${./additional-config/.p10k.zsh}
    '';

    plugins = [
      {
         name = "powerlevel10k";
         src = pkgs.zsh-powerlevel10k;
         file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
    ];
  
    sessionVariables = {
      TERM="xterm-256color";
    };

    shellGlobalAliases = {
      ls = "colorls";
    };
  };
}
