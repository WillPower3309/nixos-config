{ config, ... }:

{
  # Persistent files & directories
  directories = [
    "/etc/NetworkManager/system-connections"
    "/etc/nixos"
    "/var/log"
    "/var/lib/libvirt"
    "/var/lib/mpd"
    "/var/lib/docker"
   ];

  files = [
    "/etc/machine-id" # used by systemd for journalctl
  ];
}
