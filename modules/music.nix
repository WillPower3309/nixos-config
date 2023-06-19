{ config, pkgs, ... }:

{
  # TODO: services.mpd

  environment.systemPackages = with pkgs; [
    mpd
    ncmpcpp
    mpc_cli
    soulseekqt
    spotify
  ];

  environment.persistence."/nix/persist".directories = [ "/var/lib/mpd" ];
}
