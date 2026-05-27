{ inputs, ... }:

{
  flake.modules.homeManager.will = { pkgs, config, ... }: {
    home = {
      packages = with pkgs; [ unityhub dotnet-sdk_8 ];
      persistence."${config.constants.persistentDir}".directories = [
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
