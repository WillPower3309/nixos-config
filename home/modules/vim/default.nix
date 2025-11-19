{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;

    vimAlias = true;
    vimdiffAlias = true;
    viAlias = true;

    plugins = with pkgs.vimPlugins; [
      nvim-tree-lua
      telescope-nvim
      telescope-fzf-native-nvim
    ];
  };

  home.file.".config/nvim" = {
    source = ./config;
    recursive = true;
  };
}
