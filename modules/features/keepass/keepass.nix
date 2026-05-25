{ inputs, ... }:

{
  flake.modules.homeManager.will = { pkgs, config, lib, ... }: {

    age.secrets.keepassPassword.file = ./keepass.age;

    # TODO: https://www.reddit.com/r/NixOS/comments/1l9xbd9/how_to_declaratively_link_keepassxc_databases_to/
    home = {
      packages = with pkgs; [ keepassxc ];

      file.".cache/keepassxc/keepassxc.ini".text = lib.generators.toINI { } {
        General.LastActiveDatabase = "${config.constants.persistentDir}${config.home.homeDirectory}/keepass/vault.kdbx";
      };
    };

    xdg = let desktopEntryName = "org.keepassxc.KeePassXC"; in {
      desktopEntries."${desktopEntryName}" = {
        name = "KeePassXC";
        # TODO: not working
        exec = "sh -c \"cat \\\\${config.age.secrets.keepassPassword.path} | keepassxc --pw-stdin ${config.constants.persistentDir}/home/will/keepass/vault.kdbx\"";
      };
      autostart.entries = lib.optionals config.xdg.autostart.enable [
        "${pkgs.keepassxc}/share/applications/${desktopEntryName}.desktop"
      ];

      configFile."keepassxc/keepassxc.ini".text = lib.generators.toINI { } {
        General = {
          ConfigVersion = 2;
          MinimizeAfterUnlock = true;
        };
        Browser = {
          Enabled = true;
        };
        GUI = {
          ApplicationTheme = "dark";
          MinimizeOnStartup = true;
          MinimizeOnClose = true;
          MinimizeToTray = true;
          ShowTrayIcon = true;
          TrayIconAppearance = "monochrome-light";
        };
        Security.IconDownloadFallback = true;
      };
    };
  };
}

