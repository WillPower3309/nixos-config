{ pkgs, lib, ... }:

{
  programs.emacs = {
    enable = true;

    extraPackages = epkgs: with epkgs; [
      use-package
      all-the-icons
      projectile
      magit
      ivy
      doom-themes
      which-key
      treemacs
      treemacs-projectile
      treemacs-magit
      eshell-syntax-highlighting
      lsp-mode
      lsp-ivy
      dap-mode
      company
      yasnippet
      undo-tree
      editorconfig
      evil
      general
      org-roam
    ];
  };

  #services.emacs.enable = true;

  home.file.".emacs.d/init.el".source = ./additional-config/emacs/init.el;
}

