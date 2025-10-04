{ config, pkgs, impermanence, agenix, nixos-hardware, ... }:

{
  imports = [
    impermanence.nixosModules.impermanence
    agenix.nixosModules.default
    nixos-hardware.nixosModules.framework-16-7040-amd
    ./disks.nix
    ../../modules/android-dev.nix
    ../../modules/bluetooth.nix
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
    ../../modules/power.nix
    ../../modules/screen-record.nix
    ../../modules/sound.nix
    ../../modules/syncthing.nix
    ../../modules/users.nix
    ../../modules/web-browsers.nix
    ../../modules/wifi.nix
  ];

  boot = {
    initrd = {
      availableKernelModules = [ "nvme" "xhci_pci" "thunderbolt" "usb_storage" "usbhid" "sd_mod" ];
      kernelModules = [ "dm-snapshot" "amdgpu" ];
    };
    kernelModules = [ "kvm-amd" ];
  };
  hardware.enableAllFirmware = true;

  hardware.graphics = {
    enable = true;
    extraPackages = [ pkgs.rocmPackages.clr.icd ];
  };

  # Set your time zone.
  time.timeZone = "America/Toronto";

  networking = {
    hostName = "laptop";
    useNetworkd = true;
#    nameservers = [ "194.242.2.4#base.dns.mullvad.net" ]; # TODO: across all hosts, use var
  };

# TODO: reenable once I figure out how to make <service>.server.willmckinnon.com links work with this
#  services.resolved = {
#    enable = true;
#    dnssec = "true";
#    domains = [ "~." ];
#    fallbackDns = [ "194.242.2.4#base.dns.mullvad.net" ]; # TODO: across all hosts, use var
#    dnsovertls = "true";
#  };

  age.identityPaths = [ "/nix/persist/etc/ssh/ssh_host_ed25519_key" ];

  programs = {
    dconf.enable = true; # needed for sway
    light.enable = true; # laptop needs backlight
    fuse.userAllowOther = true; # persistence (TODO: make one file)
  };

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

  environment.variables = {
    _JAVA_AWT_WM_NONREPARENTING = "1";
    QT_QPA_PLATFORM = "wayland";
    XDG_CURRENT_DESKTOP = "sway";
    NIXOS_OZONE_WL = "1";
    GDK_BACKEND = "wayland";
  };

  environment = {
    persistence."/nix/persist" = {
      hideMounts = true;
      directories = [
        "/var/log"
        "/var/lib/nixos"
      ];
      files = [ "/etc/ssh/ssh_host_ed25519_key" ];
    };

    etc."ssh/ssh_host_ed25519_key.pub".source = ./ssh_host_ed25519_key.pub;
  };

  system.stateVersion = config.system.nixos.release;
}

