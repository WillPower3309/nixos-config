{ pkgs, inputs, ... }:

{
  imports = [
    ./games.nix
    ./greetd.nix
    ./file-management.nix
    ./fonts.nix
    ./organization.nix
    ./plymouth.nix
    ./screen-record.nix
    ./sound.nix
    ./users.nix
    ./wayland.nix
    ./web-browsers.nix
  ];

  hardware.graphics = {
    enable = true;
    extraPackages = [ pkgs.rocmPackages.clr.icd ]; # opencl
  };

  programs = {
    dconf.enable = true; # needed for sway
    fuse.userAllowOther = true; # persistence (TODO: make one file)
  };

  age.identityPaths = [ "/nix/persist/etc/ssh/ssh_host_ed25519_key" ];

  environment.systemPackages = with pkgs; [
    inputs.agenix.packages.x86_64-linux.default
    deploy-rs
    pciutils
    colorls
    gtop
    libnotify
    psmisc # fuser, killall and pstree etc
  ];
}
