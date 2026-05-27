{ inputs, ... }:

{
  flake.modules.homeManager.will = { pkgs, ... }: {
    home = {
      packages = with pkgs; [ unityhub dotnet-sdk_8 ];
      persistence."/nix/persist".directories = [
        "Unity"
        ".config/unity3d"
        ".config/unityhub"
      ];
    };

    # used by unity
    programs.vscode = {
      enable = true;
      package = pkgs.vscode.fhs;
    };
  };
}
