{ config, pkgs, impermanence, agenix, ... }:

{
  imports = [
    impermanence.nixosModules.impermanence
    agenix.nixosModules.default
    ./hardware-configuration.nix
    ../../modules/boot.nix
    ../../modules/containerization.nix
    ../../modules/evolution.nix
    ../../modules/file-management.nix
    ../../modules/fonts.nix
    ../../modules/greetd.nix
    ../../modules/kernel.nix
    ../../modules/nebula.nix
    ../../modules/nix.nix
    ../../modules/packages.nix
    ../../modules/polkit.nix # needed for sway
    ../../modules/screen-record.nix
    ../../modules/sound.nix
    ../../modules/syncthing.nix
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
    config.common.default = [ "wlr" ];
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

  system.stateVersion = "22.05";
}
