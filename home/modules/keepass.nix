{ pkgs, lib, ... }:

{
  home = {
    packages = with pkgs; [ keepassxc ];

    file.".cache/keepassxc/keepassxc.ini".text = lib.generators.toINI { } {
      General.LastActiveDatabase = "/nix/persist/home/will/keepass/vault.kbdx";
    };
  };

  xdg.configFile."keepassxc/keepassxc.ini".text = lib.generators.toINI { } {
    General = {
      ConfigVersion = 2;
      MinimizeAfterUnlock = true;
    };
    Browser.Enabled = true;
    GUI = {
      MinimizeOnClose = true;
      MinimizeToTray = true;
      ShowTrayIcon = true;
      TrayIconAppearance = "monochrome-dark";
    };

    Security.IconDownloadFallback = true;
  };
}

# https://askubuntu.com/questions/1210158/start-keepassxc-on-boot/1210421#1210421
# echo "<password>" | keepassxc --pw-stdin keepass/vault.kdbx
