{ pkgs, lib, ... }:

{
  programs.emacs = {
    enable = true;

    #package = pkgs.emacsGit;

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
      lsp-python-ms
      company
      dap-mode
      yasnippet
      undo-tree
      editorconfig
      evil
      general
      org-roam
      nix-mode
      nano-modeline
    ];
  };

  #services.emacs.enable = true;

  home.file.".emacs.d/init.el".source = ./config/emacs/init.el;
}

