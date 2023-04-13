{ pkgs, lib, ... }:

{
  programs.zsh = {
    # TODO: already enabled system wide?
    enable = true;

    defaultKeymap = "viins";

    enableAutosuggestions = true;
    enableCompletion = true;

    initExtraBeforeCompInit = ''
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
    '';
    initExtra = ''
      source ${./config/.p10k.zsh}
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
