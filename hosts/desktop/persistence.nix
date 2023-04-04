{ config, ... }:

{
  # Persistent files & directories
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

  users.will = {
    directories = [
      "Downloads"
      "Projects"
      ".steam"
      ".emacs.d"
      { directory = ".ssh"; mode = "0700"; }
    ];
  };
}
