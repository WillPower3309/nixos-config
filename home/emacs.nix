{ pkgs, ... }:

{
  programs.emacs = {
    enable = true;
    package = pkgs.emacs-gtk;
  };

  home = {
    file.".emacs.d/init.el".source = ./config/emacs/init.el;

    persistence."/nix/persist/home/will" = {
      directories = [ ".emacs.d" ];
      allowOther = true;
    };
  };
}
