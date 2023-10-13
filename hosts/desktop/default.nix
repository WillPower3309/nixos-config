{ config, pkgs, impermanence, agenix, ... }:

{
  imports = [
    impermanence.nixosModules.impermanence
    agenix.nixosModules.default
    ./hardware-configuration.nix
    ../../modules/bootloader.nix
    ../../modules/containerization.nix
    ../../modules/development.nix
    ../../modules/fonts.nix
    ../../modules/greetd.nix
    ../../modules/kernel.nix
    ../../modules/music.nix
    ../../modules/nix.nix
    ../../modules/packages.nix
    ../../modules/polkit.nix # needed for sway
    ../../modules/screen-record.nix
    ../../modules/sound.nix
    ../../modules/users.nix
  ];

  # Set your time zone.
  time.timeZone = "America/Toronto";

  networking = {
    hostName = "desktop";
    wireless.enable = false;
  };

  age.identityPaths = [ "/nix/persist/etc/ssh/ssh_host_ed25519_key" ];

  programs = {
    dconf.enable = true; # needed for sway
    fuse.userAllowOther = true; # persistence (TODO: make one file)
  };

  hardware.opengl.enable = true;
  xdg.portal = {
    enable = true;
    wlr.enable = true; # provides screen share
#    extraPortals = with pkgs; [
#      xdg-desktop-portal-gtk # provides file chooser
#    ];
  };

  # TODO: make this across all hosts, remove agenix import here
  # TODO: get deploy-rs file from flake too?
  environment.systemPackages = with pkgs; [
    deploy-rs
    agenix.packages.x86_64-linux.default
  ];

  environment = {
    persistence."/nix/persist" = {
      hideMounts = true;
      directories = [ "/var/log" ];
      files = [
        "/etc/machine-id" # used by systemd for journalctl
        "/etc/ssh/ssh_host_ed25519_key"
      ];
    };

    etc."ssh/ssh_host_ed25519_key.pub".source = ./ssh_host_ed25519_key.pub;
  };

  age.secrets = {
    desktopSyncthingKey.file = ../../secrets/desktopSyncthingKey.age;
    desktopSyncthingCert.file = ../../secrets/desktopSyncthingCert.age;
  };

  services.syncthing = {
    enable = true;
    dataDir = "/syncthing";
    openDefaultPorts = true;
    overrideDevices = true; # overrides any devices added or deleted through the WebUI
    overrideFolders = true; # overrides any folders added or deleted through the WebUI
    guiAddress = "0.0.0.0:8384";
    key = config.age.secrets.desktopSyncthingKey.path;
    cert = config.age.secrets.desktopSyncthingCert.path;

    settings = {
      options.urAccepted = -1;

      devices = {
        server = {
          id = "V5AV6D5-5ITLYTL-35UHX6S-LKMFZ6U-FVGLEZP-EFGGR3R-O6AVGG7-ONT5MQE";
          autoAcceptFolders = true;
        };
      };
    };
  };
  networking.firewall.allowedTCPPorts = [ 8384 ];

  system.stateVersion = "22.05";
}
