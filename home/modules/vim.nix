{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;

    vimAlias = true;
    vimdiffAlias = true;
    viAlias = true;

    plugins = with pkgs.vimPlugins; [
      ayu-vim
      vim-airline
      indentLine
    ];

    extraConfig = ''
      " Usability
      set smarttab
      set tabstop=4
      set shiftwidth=4
      " use spaces instead of tabs
      set expandtab

      " KEYBINDS
      " Copy / Paste From Keyboard
      vnoremap <leader>y "+y
      vnoremap <leader>p "+p
      " j/k will move virtual lines (lines that wrap)
      noremap <silent> <expr> j (v:count == 0 ? 'gj' : 'j')
      noremap <silent> <expr> k (v:count == 0 ? 'gk' : 'k')

      " Line number settings
      set number relativenumber
      augroup numbertoggle
        autocmd!
        autocmd BufEnter,FocusGained,InsertLeave    * set relativenumber
        autocmd BufEnter,FocusLost,InsertEnter      * set norelativenumber
      augroup end

      " Make comments italic
      highlight comment cterm=italic gui=italic

    " theme
      set termguicolors
      let ayucolor="mirage"
      colorscheme ayu

    " --------- bling/vim-airline settings -------------
      " always show statusbar
      set laststatus=2
      " show paste if in paste mode
      let g:airline_detect_paste=1
      " use powerline font extras (arrows)
      let g:airline_powerline_fonts=1
      " show airline for tabs
      let g:airline#extension#tabline#enabled=1

      " --------- indentLine settings -------------------
      let g:indentLine_showFirstLevelIndent=1
      let g:indentLine_setColors=0
    '';
  };
}
