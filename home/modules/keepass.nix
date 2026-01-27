{ pkgs, config, lib, ... }:

{
  # TODO: https://www.reddit.com/r/NixOS/comments/1l9xbd9/how_to_declaratively_link_keepassxc_databases_to/
  home = {
    packages = with pkgs; [ keepassxc ];

    file.".cache/keepassxc/keepassxc.ini".text = lib.generators.toINI { } {
      General.LastActiveDatabase = "/nix/persist/home/will/keepass/vault.kdbx";
    };
  };

  xdg.configFile."keepassxc/keepassxc.ini".text = lib.generators.toINI { } {
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
}

