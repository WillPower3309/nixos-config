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

  home = {
    packages = with pkgs; [
      clang-tools # c / cpp
    ];

    file.".config/nvim" = {
      source = ./config;
      recursive = true;
    };
  };
}
