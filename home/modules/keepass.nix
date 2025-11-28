{ pkgs, lib, ... }:

{
  home = {
    packages = with pkgs; [ keepassxc ];

    file = {
      ".cache/keepassxc/keepassxc.ini".text = lib.generators.toINI { } {
        General.LastActiveDatabase = "/nix/persist/home/will/keepass/vault.kdbx";
      };

      ".mozilla/native-messaging-hosts/org.keepassxc.keepassxc_browser.json".text = lib.generators.toJSON { } {
        "allowed_extensions" = [ "keepassxc-browser@keepassxc.org" ];
        "description" = "KeePassXC integration with native messaging support";
        "name" = "org.keepassxc.keepassxc_browser";
        # TODO: properly get path
        "path" = "/nix/store/x2xi0dpkm8db7knl9z2bwpqqxhlznns0-keepassxc-2.7.10/bin/keepassxc-proxy";
        "type" = "stdio";
      };
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
      ApplicationTheme= "dark";
      MinimizeOnClose = true;
      MinimizeToTray = true;
      ShowTrayIcon = true;
      TrayIconAppearance = "monochrome-light";
    };

    Security.IconDownloadFallback = true;
  };
}

# https://askubuntu.com/questions/1210158/start-keepassxc-on-boot/1210421#1210421
# echo "<password>" | keepassxc --pw-stdin keepass/vault.kdbx
