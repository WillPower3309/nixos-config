{ inputs, ... }:

{
  flake.modules.homeManager.document-viewer = { ... }: {
    # TODO: ensure mupdf plugin is used
    programs.zathura.enable = true;
  };
}
