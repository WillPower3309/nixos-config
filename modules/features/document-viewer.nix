{ inputs, ... }:

{
  flake.modules.homeManager.will = { ... }: {
    # TODO: ensure mupdf plugin is used
    programs.zathura.enable = true;
  };
}
