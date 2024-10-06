{ pkgs, ... }:

{
  home = {
    packages = with pkgs; [ unityhub dotnet-sdk_8 ];
    persistence."/nix/persist/home/will".directories = [
      "Unity"
      ".config/unity3d"
      ".config/unityhub"
    ];
  };
  programs.vscode = {
    enable = true;
    package = pkgs.vscode.fhs;
  };
}

