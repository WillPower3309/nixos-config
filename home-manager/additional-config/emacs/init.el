;; -*- lexical-binding: t -*-

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; INITIALIZATION
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Remove package.el (since using nix to manage packages)
(setq package-enable-at-startup nil)

;; Personal information
(setq user-full-name "Will McKinnon"
      user-mail-address "contact@willmckinnon.com")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; UI LAYOUT
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; No startup  screen
(setq inhibit-startup-screen t)

;; No startup message
(setq inhibit-startup-message t)
(setq inhibit-startup-echo-area-message t)

;; No message in scratch buffer
(setq initial-scratch-message nil)

;; Initial buffer
(setq initial-buffer-choice nil)

;; No frame title
(setq frame-title-format nil)

;; No file dialog
(setq use-file-dialog nil)

;; No dialog box
(setq use-dialog-box nil)

;; No popup windows
(setq pop-up-windows nil)

;; No empty line indicators
(setq indicate-empty-lines nil)

;; No cursor in inactive windows
(setq cursor-in-non-selected-windows nil)

;; Text mode is initial mode
(setq initial-major-mode 'text-mode)

;; Text mode is default major mode
(setq default-major-mode 'text-mode)

;; No cursor in inactive windows
(setq cursor-in-non-selected-windows nil)

;; Moderate font lock
(setq font-lock-maximum-decoration nil)

;; No limit on font lock
(setq font-lock-maximum-size nil)

;; No line break space points
(setq auto-fill-mode nil)

;; Fill column at 80
(setq fill-column 80)

;; No scroll bars
(scroll-bar-mode -1)

;; No toolbar
(tool-bar-mode -1)

;; No menu bar (may have problems on macOS)
(menu-bar-mode -1)

;; Wrap lines
(global-visual-line-mode t)

;; Minimum window height
(setq window-min-height 1)

;; Shorten "yes" or "no" to y/n
(fset 'yes-or-no-p 'y-or-n-p)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; THEME
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Treemacs Nord theme
(use-package doom-themes
  :after treemacs
  :config
  (load-theme 'doom-nord t)
  (setq doom-themes-treemacs-theme "doom-colors")
  (doom-themes-treemacs-config))

;; Nano (TODO: better way)
(add-to-list 'load-path "/etc/nixos/home-manager/additional-config/emacs/nano-emacs")

;; TODO: ui elements reappear on refocus
(require 'nano-layout)

(require 'nano-theme-dark)

(require 'nano-faces)
(nano-faces)

(require 'nano-theme)
(nano-theme)

(require 'nano-modeline)

(require 'nano-splash)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Org Mode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Nano writer
(require 'nano-writer)
(add-to-list 'auto-mode-alist '("\\.org\\'" . writer-mode))

; Org Roam
(use-package org-roam
  :custom
  (org-roam-directory (file-truename "~/Nextcloud/Notes"))
  :bind (("C-c n l" . org-roam-buffer-toggle)
         ("C-c n f" . org-roam-node-find)
         ("C-c n g" . org-roam-graph)
         ("C-c n i" . org-roam-node-insert)
         ("C-c n c" . org-roam-capture)
         ;; Dailies
         ("C-c n j" . org-roam-dailies-capture-today))
  :config
  (org-roam-db-autosync-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; UX
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Completion style, see
;; gnu.org/software/emacs/manual/html_node/emacs/Completion-Styles.html
(setq completion-styles '(basic substring))

;; Enable which-key
(use-package which-key
  :init
  (setq which-key-side-window-location 'bottom
        which-key-sort-order #'which-key-key-order-alpha
        which-key-sort-uppercase-first nil
        which-key-add-column-padding 1
        which-key-max-display-columns nil
        which-key-min-display-lines 6
        which-key-side-window-slot -10
        which-key-side-window-max-height 0.25
        which-key-idle-delay 0.8
        which-key-max-description-length 25
        which-key-allow-imprecise-window-fit t
        which-key-separator " → " ))
(which-key-mode)


;; Spaces over tabs
(setq-default indent-tabs-mode nil)
(setq-default tab-width 4)

;; Clean up whitespace on save
(add-hook 'before-save-hook 'whitespace-cleanup)

;; Pixel scroll (as opposed to char scroll)
(pixel-scroll-mode t)

;; macOS specific
(when (eq system-type 'darwin)
  (setq ns-use-native-fullscreen t
        mac-option-key-is-meta nil
        mac-command-key-is-meta t
        mac-command-modifier 'meta
        mac-option-modifier nil
        mac-use-title-bar nil))

;; Buffer encoding
(prefer-coding-system       'utf-8)
(set-default-coding-systems 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(set-language-environment   'utf-8)

;; Unique buffer names
(require 'uniquify)
(setq uniquify-buffer-name-style 'reverse
      uniquify-separator " • "
      uniquify-after-kill-buffer-p t
      uniquify-ignore-buffers-re "^\\*")

;; Kill term buffer when exiting
(defadvice term-sentinel (around my-advice-term-sentinel (proc msg))
  (if (memq (process-status proc) '(signal exit))
      (let ((buffer (process-buffer proc)))
        ad-do-it
        (kill-buffer buffer))
    ad-do-it))
(ad-activate 'term-sentinel)

(setq gc-cons-threshold (* 100 1024 1024)
      read-process-output-max (* 1024 1024)
;      treemacs-space-between-root-nodes nil
      company-idle-delay 0.0
      company-minimum-prefix-length 1
      lsp-idle-delay 0.1)

; Project management and tools
(use-package projectile
  :config
  (setq projectile-completion-system 'ivy)
  (projectile-mode +1))

;; Treemacs
(use-package treemacs
  :config
  (setq treemacs-git-mode 'simple
        treemacs-follow-mode t
        treemacs-filewatch-mode t))

(use-package treemacs-projectile
  :after treemacs)
(use-package treemacs-magit
  :after treemacs magit)

;; TODO: fix
(use-package eshell-syntax-highlighting
  :after esh-mode
  :config
  (eshell-syntax-highlighting-global-mode +1))

;; Web mode
;; TODO: ensure works with css
;(use-package web-mode
;  :mode (("\\.js\\'" . web-mode)
;	("\\.jsx\\'" . web-mode)
;	("\\.ts\\'" . web-mode)
;	("\\.tsx\\'" . web-mode)
;	("\\.html\\'" . web-mode)
;	("\\.vue\\'" . web-mode)
;	("\\.json\\'" . web-mode)))

; LSP mode
(use-package lsp-mode
  :hook
  ;; TODO: syntax highlighting issue with web-mode
  ;(web-mode . lsp-deferred)
  (prog-mode . lsp-deferred)
  (lsp-mode . lsp-enable-which-key-integration)
  :config
  (setq lsp-auto-guess-root t
	lsp-headerline-breadcrumb-enable nil
	lsp-eldoc-enable-hover nil
        lsp-file-watch-ignored'("[/\\\\]\\.git$"
                                "[/\\\\]\\.elixir_ls$"
                                "[/\\\\]_build$"
                                "[/\\\\]assets$"
                                "[/\\\\]cover$"
                                "[/\\\\]node_modules$"
                                "[/\\\\]submodules$")))
(use-package lsp-ivy
  :after lsp-mode
  :commands lsp-ivy-workspace-symbol)

;; DAP Mode
(use-package dap-mode
  :after lsp-mode
  ;(require 'dap-node)
  ;(require 'dap-cpptools)
  :hook
  (prog-mode 'enable-dap-mode-and-ui))

;; Yasnippet
(use-package yasnippet :config (yas-global-mode 1))

;; Use undo-tree for undo functionality
(use-package undo-tree
  :config
  (setq undo-tree-history-directory-alist '(("." . "~/.emacs.d/undo")))
  (setq undo-tree-auto-save-history t)
  (global-undo-tree-mode 1))

;; EditorConfig support
(use-package editorconfig
  :config
  (editorconfig-mode 1))

;; Dired
(autoload 'dired-jump "dired-x"
  "Jump to Dired buffer corresponding to current buffer." t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; KEYBINDS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Evil Bindings
(use-package evil
  :after undo-tree
  :init
  (setq evil-undo-system 'undo-tree)
  :config
  (evil-mode))

(use-package general
  :config
  (general-evil-setup t))

;; General Keybinds
(nvmap :keymaps 'override :prefix "SPC"
  ":"     '(counsel-M-x :which-key "M-x")
  "h r r" '((lambda () (interactive) (load-file "~/.emacs.d/init.el")) :which-key "Reload emacs config")

  "."     '(dired-jump :which-key "Find file (Dir)")
  "SPC"   '(projectile-find-file :which-key "Find File (Project)"))

;; Window Keybinds
(nvmap :prefix "SPC"
  "w c"   '(evil-window-delete :which-key "Close window")
  "w n"   '(evil-window-new :which-key "New window")
  "w s"   '(evil-window-split :which-key "Horizontal split window")
  "w v"   '(evil-window-vsplit :which-key "Vertical split window")

  "w h"   '(evil-window-left :which-key "Window left")
  "w j"   '(evil-window-down :which-key "Window down")
  "w k"   '(evil-window-up :which-key "Window up")
  "w l"   '(evil-window-right :which-key "Window right"))

;; Module Keybinds
(nvmap :prefix "SPC"
  "o p"   '(treemacs :which-key "Open Treemacs")
  "o e"   '(eshell :which-key "Open Eshell")

  "p p"   '(projectile-switch-project :which-key "Open Project"))

;; Buffer Keybinds
(nvmap :prefix "SPC"
       "b b"   '(ibuffer :which-key "Ibuffer")
       "b c"   '(clone-indirect-buffer-other-window :which-key "Clone indirect buffer other window")
       "b k"   '(kill-current-buffer :which-key "Kill current buffer")
       "b n"   '(next-buffer :which-key "Next buffer")
       "b p"   '(previous-buffer :which-key "Previous buffer")
       "b B"   '(ibuffer-list-buffers :which-key "Ibuffer list buffers")
       "b K"   '(kill-buffer :which-key "Kill buffer"))

