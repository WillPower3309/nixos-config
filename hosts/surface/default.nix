{ config, pkgs, impermanence, agenix, ... }:

{
  imports = [
    impermanence.nixosModules.impermanence
    agenix.nixosModules.default
    ./hardware-configuration.nix
    ../../modules/bluetooth.nix
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
    ../../modules/syncthing-client.nix
    ../../modules/users.nix
    ../../modules/wifi.nix
  ];

  # Set your time zone.
  time.timeZone = "America/Toronto";

  networking.hostName = "surface";

  age.identityPaths = [ "/nix/persist/etc/ssh/ssh_host_ed25519_key" ];

  programs = {
    dconf.enable = true; # needed for sway
    light.enable = true; # laptop needs backlight
    fuse.userAllowOther = true; # persistence (TODO: make one file)
  };

  # needed for sway
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

  age.secrets = {
    surfaceSyncthingKey.file = ../../secrets/surfaceSyncthingKey.age;
    surfaceSyncthingCert.file = ../../secrets/surfaceSyncthingCert.age;
  };

  services.syncthing = {
    key = config.age.secrets.surfaceSyncthingKey.path;
    cert = config.age.secrets.surfaceSyncthingCert.path;
  };

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

  system.stateVersion = "22.05";
}
