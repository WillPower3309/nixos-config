{ inputs, ... }:

{
  flake.modules.homeManager.will = { pkgs, ... }: {
    programs.opencode = {
      enable = true;
      settings = {
        model = "opencode/deepseek-v4-flash-free";
        lsp = true;
        autoshare = false;
        autoupdate = false;
      };
      tui.theme = "system";
    };

    home.packages = [ pkgs.lazygit ];
  };
}
