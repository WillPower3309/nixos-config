;; -*- lexical-binding: t -*-

;; Personal information
(setq user-full-name "Will McKinnon"
      user-mail-address "contact@willmckinnon.com")


;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CORE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;
;; Package Management
;;;;;;;;;;;;;;;;;;;;;;;

(setq straight-check-for-modifications nil)

(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory))
      (bootstrap-version 5))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/raxod502/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

;;;;;;;;;;;;;;;;;;;;;;;
;; Package Installation
;;;;;;;;;;;;;;;;;;;;;;;

(setq package-list
  '(use-package
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
    nix-mode))

; install packages that are not yet installed
(dolist (package package-list)
  (straight-use-package package))

;; NANO splash
(straight-use-package
 '(nano-splash :type git :host github :repo "rougier/nano-splash"))

;; NANO theme
(straight-use-package
 '(nano-theme :type git :host github :repo "rougier/nano-theme"))

;; NANO modeline
(straight-use-package
 '(nano-modeline :type git :host github :repo "rougier/nano-modeline"))

;; NANO minibuffer
(straight-use-package
 '(nano-minibuffer :type git :host github :repo "rougier/nano-minibuffer"))

;; NANO agenda
(straight-use-package
 '(nano-agenda :type git :host github :repo "rougier/nano-agenda"))

;; SVG tags, progress bars & icons
(straight-use-package
 '(svg-lib :type git :host github :repo "rougier/svg-lib"))

;; Replace keywords with SVG tags
(straight-use-package
 '(svg-tag-mode :type git :host github :repo "rougier/svg-tag-mode"))

;;;;;;;;;;;;;;;;;;;;;;;
;; Startup
;;;;;;;;;;;;;;;;;;;;;;;

(setq-default
  inhibit-startup-screen t               ; Disable start-up screen
  inhibit-startup-message t              ; Disable startup message
  inhibit-startup-echo-area-message t    ; Disable initial echo message
  initial-scratch-message ""             ; Empty the initial *scratch* buffer
  initial-buffer-choice t)               ; Open *scratch* buffer at init

;;;;;;;;;;;;;;;;;;;;;;;
;; Encoding
;;;;;;;;;;;;;;;;;;;;;;;

(set-default-coding-systems 'utf-8)     ; Default to utf-8 encoding
(prefer-coding-system       'utf-8)     ; Add utf-8 at the front for automatic detection.
(set-default-coding-systems 'utf-8)     ; Set default value of various coding systems
(set-terminal-coding-system 'utf-8)     ; Set coding system of terminal output
(set-keyboard-coding-system 'utf-8)     ; Set coding system for keyboard input on TERMINAL
(set-language-environment "English")    ; Set up multilingual environment

;;;;;;;;;;;;;;;;;;;;;;;
;; Dialogs
;;;;;;;;;;;;;;;;;;;;;;;

(setq-default show-help-function nil    ; No help text
              use-file-dialog nil       ; No file dialog
              use-dialog-box nil        ; No dialog box
              pop-up-windows nil)       ; No popup windows

(tooltip-mode -1)                       ; No tooltips
(scroll-bar-mode -1)                    ; No scroll bars
(tool-bar-mode -1)                      ; No toolbar

;; Specific case for OSX since menubar is desktop-wide.
(if (and (eq system-type 'darwin)
         (display-graphic-p))
    (menu-bar-mode 1) 
  (menu-bar-mode -1))

;;;;;;;;;;;;;;;;;;;;;;;
;; Sound
;;;;;;;;;;;;;;;;;;;;;;;

(setq-default visible-bell nil             ; No visual bell      
              ring-bell-function 'ignore)  ; No bell

;;;;;;;;;;;;;;;;;;;;;;;
;; Scroll
;;;;;;;;;;;;;;;;;;;;;;;

(setq-default scroll-conservatively 101       ; Avoid recentering when scrolling far
              scroll-margin 2                 ; Add a margin when scrolling vertically
              recenter-positions '(5 bottom)) ; Set re-centering positions

;;;;;;;;;;;;;;;;;;;;;;;
;; Clipboard
;;;;;;;;;;;;;;;;;;;;;;;

(setq-default select-enable-clipboard t) ; Merge system's and Emacs' clipboard

;;;;;;;;;;;;;;;;;;;;;;;
;; Backup & Lock Files
;;;;;;;;;;;;;;;;;;;;;;;

; No lock files
(setq create-lockfiles nil)

; Backup files config
(setq
  backup-directory-alist
    `((".*" . ,temporary-file-directory))
  auto-save-file-name-transforms
    `((".*" ,temporary-file-directory t))
  backup-by-copying t
  delete-old-versions t
  kept-new-versions 6
  kept-old-versions 2
  version-control t)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; VISUAL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;
;; Colors
;;;;;;;;;;;;;;;;;;;;;;;

(require 'nano-theme)
(setq nano-fonts-use t)
(nano-dark)
(nano-mode)

;;;;;;;;;;;;;;;;;;;;;;;
;; Splash
;;;;;;;;;;;;;;;;;;;;;;;

(require 'nano-splash)

;;;;;;;;;;;;;;;;;;;;;;;
;; Fonts
;;;;;;;;;;;;;;;;;;;;;;;


(set-face-attribute 'default nil
                    :family "Roboto Mono"
                    :weight 'light
                    :height 140)

(set-face-attribute 'bold nil
                    :family "Roboto Mono"
                    :weight 'regular)

(set-face-attribute 'italic nil
                    :family "Victor Mono"
                    :weight 'semilight
                    :slant 'italic)

(set-fontset-font t 'unicode
                    (font-spec :name "Inconsolata Light"
                               :size 16) nil)

(set-fontset-font t '(#xe000 . #xffdd)
                     (font-spec :name "RobotoMono Nerd Font"
                                :size 12) nil)

;;;;;;;;;;;;;;;;;;;;;;;
;; Typography
;;;;;;;;;;;;;;;;;;;;;;;

(setq-default
  fill-column 80                          ; Default line width 
  sentence-end-double-space nil           ; Use a single space after dots
  bidi-paragraph-direction 'left-to-right ; Faster
  truncate-string-ellipsis "…")           ; Nicer ellipsis

(require 'nano-theme)

;; Nicer glyphs for continuation and wrap 
(set-display-table-slot standard-display-table 'truncation (make-glyph-code ?… 'nano-faded))

(defface wrap-symbol-face
  '((t (:family "Fira Code"
        :inherit nano-faded)))
  "Specific face for wrap symbol")

(set-display-table-slot standard-display-table 'wrap (make-glyph-code ?↩ 'wrap-symbol-face))

; Fix a bug on OSX in term mode & zsh (spurious “%” after each command)
(when (eq system-type 'darwin)
  (add-hook 'term-mode-hook
            (lambda ()
              (setq buffer-display-table (make-display-table)))))

; ensure underline is positionned at the very bottom
(setq
  x-underline-at-descent-line nil
  x-use-underline-position-properties t
  underline-minimum-offset 10)

;;;;;;;;;;;;;;;;;;;;;;;
;; Modeline
;;;;;;;;;;;;;;;;;;;;;;;

(require 'nano-theme)
(require 'nano-modeline)

(nano-modeline-mode 1)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; EDITING
;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;
;; Spaces & Tabs
;;;;;;;;;;;;;;;;;;;;;;;

(setq-default indent-tabs-mode nil)
(setq-default tab-width 4)

;;;;;;;;;;;;;;;;;;;;;;;
;; Whitespace
;;;;;;;;;;;;;;;;;;;;;;;

;; Clean up whitespace on save
(add-hook 'before-save-hook 'whitespace-cleanup)

;;;;;;;;;;;;;;;;;;;;;;;
;; Undo-tree
;;;;;;;;;;;;;;;;;;;;;;;

(use-package undo-tree
  :config
  (setq undo-tree-history-directory-alist '(("." . "~/.emacs.d/undo")))
  (setq undo-tree-auto-save-history t)
  (global-undo-tree-mode 1))

;;;;;;;;;;;;;;;;;;;;;;;
;; Projectile & Treemacs
;;;;;;;;;;;;;;;;;;;;;;;

(use-package projectile
  :config
  (setq projectile-completion-system 'ivy)
  (projectile-mode +1))

(use-package treemacs
  :config
  (setq
    treemacs-git-mode 'simple
    treemacs-follow-mode t
    treemacs-filewatch-mode t))

(use-package treemacs-projectile
  :after treemacs projectile)
(use-package treemacs-magit
  :after treemacs magit)


;;;;;;;;;;;;;;;;;;;;;;;
;; EditorConfig support
;;;;;;;;;;;;;;;;;;;;;;;

(use-package editorconfig
  :config
  (editorconfig-mode 1))

;;;;;;;;;;;;;;;;;;;;;;;
;; LSP Mode
;;;;;;;;;;;;;;;;;;;;;;;

(use-package lsp-python-ms
  :hook 
  (python-mode . (lambda ()
    (require 'lsp-python-ms)
    (lsp)))
  :init
  (setq lsp-python-ms-executable (executable-find "python-language-server")))

(use-package nix-mode
  :mode "\\.nix\\'")

(use-package lsp-mode
  :hook
  (python-mode . lsp-deferred)
  (c-mode      . lsp-deferred)
  (nix-mode    . lsp-deferred)
  (lsp-mode . lsp-enable-which-key-integration)
  :config
  (setq
    lsp-auto-guess-root t
    lsp-headerline-breadcrumb-enable nil
    lsp-eldoc-enable-hover nil
    lsp-log-io nil
    lsp-file-watch-ignored'(
      "[/\\\\]\\.git$"
      "[/\\\\]\\.cache"
      "[/\\\\]\\.elixir_ls$"
      "[/\\\\]_build$"
      "[/\\\\]assets$"
      "[/\\\\]cover$"
      "[/\\\\]node_modules$"
      "[/\\\\]submodules$")))

;;;;;;;;;;;;;;;;;;;;;;;
;; DAP Mode
;;;;;;;;;;;;;;;;;;;;;;;

;; DAP Mode
(use-package dap-mode
  :after lsp-mode
  :hook
  (prog-mode 'enable-dap-mode-and-ui))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ORG MODE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;
;; Org Roam
;;;;;;;;;;;;;;;;;;;;;;;

; TODO

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; KEYBINDS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;
;; Evil Mode
;;;;;;;;;;;;;;;;;;;;;;;

(use-package evil
  :after undo-tree
  :init
  (setq evil-undo-system 'undo-tree)
  :config
  (evil-mode))

;;;;;;;;;;;;;;;;;;;;;;;
;; General Keybinds
;;;;;;;;;;;;;;;;;;;;;;;

(use-package general
  :config
  (general-evil-setup t))

(nvmap :keymaps 'override :prefix "SPC"
  ":"     '(counsel-M-x :which-key "M-x")
  "h r r" '((lambda () (interactive) (load-file "~/.emacs.d/init.el")) :which-key "Reload emacs config")
  "."     '(dired-jump :which-key "Find file (Dir)")
  "SPC"   '(projectile-find-file :which-key "Find File (Project)"))

;;;;;;;;;;;;;;;;;;;;;;;
;; Window Keybinds
;;;;;;;;;;;;;;;;;;;;;;;

(nvmap :prefix "SPC"
  "w c"   '(evil-window-delete :which-key "Close window")
  "w n"   '(evil-window-new :which-key "New window")
  "w s"   '(evil-window-split :which-key "Horizontal split window")
  "w v"   '(evil-window-vsplit :which-key "Vertical split window")

  "w h"   '(evil-window-left :which-key "Window left")
  "w j"   '(evil-window-down :which-key "Window down")
  "w k"   '(evil-window-up :which-key "Window up")
  "w l"   '(evil-window-right :which-key "Window right")

  ;; todo: fix me
  "w H"   '(evil-window-move-far-left :which-key "Move window left")
  "w J"   '(evil-window-move-far-down :which-key "Move window down")
  "w K"   '(evil-window-move-far-up :which-key "Move window up")
  "w L"   '(evil-window-move-far-right :which-key "Move window right"))

;;;;;;;;;;;;;;;;;;;;;;;
;; Module Keybinds
;;;;;;;;;;;;;;;;;;;;;;;

(nvmap :prefix "SPC"
  "o p"   '(treemacs :which-key "Open Treemacs")
  "o e"   '(eshell :which-key "Open Eshell")

  "p p"   '(projectile-switch-project :which-key "Open Project"))

;;;;;;;;;;;;;;;;;;;;;;;
;; Buffer Keybinds
;;;;;;;;;;;;;;;;;;;;;;;

(nvmap :prefix "SPC"
  "b b"   '(ibuffer :which-key "Ibuffer")
  "b c"   '(clone-indirect-buffer-other-window :which-key "Clone indirect buffer other window")
  "b k"   '(kill-current-buffer :which-key "Kill current buffer")
  "b n"   '(next-buffer :which-key "Next buffer")
  "b p"   '(previous-buffer :which-key "Previous buffer")
  "b B"   '(ibuffer-list-buffers :which-key "Ibuffer list buffers")
  "b K"   '(kill-buffer :which-key "Kill buffer"))

