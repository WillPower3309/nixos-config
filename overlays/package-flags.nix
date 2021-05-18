self: super:

let
  emacs-base = super.emacs.override  {
    withGTK2 = false;
    withGTK3 = false;
    withX = true;
  };
  withpkgs = (super.emacsPackagesGen emacs-base).emacsWithPackages;

in {
  emacs = withpkgs (epkgs:
    (with epkgs.melpaPackages; [
      # MELPA PACKAGES GO HERE
      use-package
      evil
      general
      projectile
      treemacs
      treemacs-evil
      lsp-mode
      helm-lsp
      helm-xref
      dap-mode
      yasnippet
      which-key
    ]) ++

    (with epkgs.elpaPackages; [
      # ELPA PACKAGES GO HERE
    ]) ++

    (with self.pkgs; [
      # SELF PACKAGES GO HERE
    ])
  );
}
