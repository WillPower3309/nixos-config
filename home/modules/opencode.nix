{ pkgs, ... }:

{
  programs.opencode = {
    enable = true;
    settings = {
      theme = "system";
      model = "opencode/deepseek-v4-flash-free";
      lsp = true;
      autoshare = false;
      autoupdate = false;
    };
  };

  home.packages = [ pkgs.lazygit ];
}
