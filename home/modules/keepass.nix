{ pkgs, lib, ... }:

{
  home = {
    packages = with pkgs; [ keepassxc ];

    file.".config/keepassxc/keepassxc.ini".text = lib.generators.toINI { } {
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

    persistence."/nix/persist/home/will" = {
      directories = [ "keepass" ];
      files = [ ".cache/keepassxc/keepassxc.ini" ];
    };
  };
}

# https://askubuntu.com/questions/1210158/start-keepassxc-on-boot/1210421#1210421
# echo "<password>" | keepassxc --pw-stdin keepass/vault.kdbx
