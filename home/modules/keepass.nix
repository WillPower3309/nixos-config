{ pkgs, lib, ... }:

{
  # TODO: why does this not work?
  age.secrets.keyfile.file = ../../secrets/keepassKeyFile.age;

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
      files = [ "~/.cache/keepassxc/keepassxc.ini" ];
    };
  };
}
