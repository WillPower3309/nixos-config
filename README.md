# nixos-config
My personal nixos config

## Installation

1. Download and flash the NixOS minimal iso to an installation media drive
2. Boot into the installation media and switch to the root user: `sudo su`
3. Read [tmpfs as root](https://elis.nu/blog/2020/05/nixos-tmpfs-as-root/#step-1-partitioning) for an understanding of how the general config works and how to mount the filesystems in a tmpfs as root setup
4. Mount the filesystems as specified in the article above
5. Connect to the internet: `sudo systemctl start wpa_supplicant` then `wpa_cli`
6. Run `wget https://raw.githubusercontent.com/WillPower3309/nixos-config/master/shell.nix` and then `nix-shell` to enter a shell with nix-command and nixFlakes enabled
7. `mkdir /mnt/etc` and clone this repo: `nix flake clone github:willpower3309/nixos-config --dest /mnt/etc/nixos`
8. Generate initial config + hardware config: `sudo nixos-generate-config --root /mnt`
9. Run `sudo nixos-install --option pure-eval no --flake $FLAKE#farnsworth`
