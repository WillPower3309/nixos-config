{ inputs, ... }:

{
  flake.modules.homeManager.will = { pkgs, config, lib, ... }: {

    age.secrets.keepassPassword.file = ./keepass.age;

    home = {
      packages = [ pkgs.keepassxc ];

      file.".cache/keepassxc/keepassxc.ini".text = lib.generators.toINI { } {
        General.LastActiveDatabase = "${config.constants.persistentDir}${config.home.homeDirectory}/keepass/vault.kdbx";
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

    systemd.user.services.keepassxc = {
      Unit = {
        Description = "KeePassXC password manager";
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.bash}/bin/sh -c 'cat ${config.age.secrets.keepassPassword.path} | ${pkgs.keepassxc}/bin/keepassxc --pw-stdin ${config.constants.persistentDir}/home/will/keepass/vault.kdbx'";
        Type = "exec";
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}

