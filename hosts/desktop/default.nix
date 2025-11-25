{ config, pkgs, impermanence, agenix, ... }:

{
  imports = [
    impermanence.nixosModules.impermanence
    agenix.nixosModules.default
    ./disks.nix
    ../../modules/boot.nix
    #../../modules/containerization.nix
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
    ../../modules/web-browsers.nix
  ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "amdgpu" ];
  hardware.enableAllFirmware = true;

  # Set your time zone.
  time.timeZone = "America/Toronto";

  networking = {
    useNetworkd = true; # systemd-networkd is faster at startup by default and more actively maintained TODO: set up with `systemd.network`
    hostName = "desktop";
    wireless.enable = false; # no wpa_supplicant needed for an ethernet connection
    nameservers = [ "194.242.2.4#base.dns.mullvad.net" ]; # TODO: across all hosts, use var
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
    fuse.userAllowOther = true; # persistence (TODO: make one file)
  };

  hardware.graphics = {
    enable = true;
    extraPackages = [ pkgs.rocmPackages.clr.icd ]; # enable opencl
  };

  xdg.portal = {
    enable = true;
    wlr.enable = true; # provides screen share
    config.common.default = [ "wlr" ];
  };

  # TODO: convert to systemd.mounts as described in https://nixos.wiki/wiki/NFS ?
  # TODO: move to photography module
  fileSystems."/mnt/photos" = {
    device = "10.27.27.6:/photos";
    fsType = "nfs";
    # lazy mount, disconnect after 10 minutes
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600" ];
  };

  fileSystems."/mnt/music" = {
    device = "10.27.27.6:/music";
    fsType = "nfs";
    # lazy mount, disconnect after 10 minutes
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600" ];
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

  hardware.cpu.amd.updateMicrocode = config.hardware.enableRedistributableFirmware;
  system.stateVersion = config.system.nixos.release;
}

