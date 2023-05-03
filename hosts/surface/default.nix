{ config, pkgs, impermanence, flake-overlays, ... }:

{
  imports = [
    impermanence.nixosModules.impermanence
    ./hardware-configuration.nix
    ../../modules/boot.nix
    ../../modules/kernel.nix
    ../../modules/greetd.nix
    ../../modules/sway.nix
    ../../modules/net.nix
    ../../modules/sound.nix
    ../../modules/users.nix
    ../../modules/fonts.nix
    ../../modules/vim.nix
    ../../modules/music.nix
    ../../modules/development.nix
    ../../modules/packages.nix
  ];

  # Set your time zone.
  time.timeZone = "America/Toronto";

  # Laptop: Needs backlight
  # TODO: use light?
  environment.systemPackages = with pkgs; [
    brightnessctl
  ];

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  nixpkgs = {
    # TODO: overlays
    # overlays = flake-overlays;
    config = {
      allowUnfree = true;
      oraclejdk.accept_license = true;
    };
  };

  # persistence (TODO: make one file)
  programs.fuse.userAllowOther = true;

  environment.persistence."/nix/persist" = {
    directories = [
      "/etc/NetworkManager/system-connections"
      "/var/log"
      "/var/lib/libvirt"
      "/var/lib/mpd"
      "/var/lib/docker"
    ];

    files = [
      "/etc/machine-id" # used by systemd for journalctl
    ];
  };

  system.stateVersion = "22.05";
}