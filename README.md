# nixos-config
My personal nixos config

## Installation

1. Download and flash the NixOS minimal iso to an installation media drive
2. Boot into the installation media and switch to the root user: `sudo su`
3. Read [tmpfs as root](https://elis.nu/blog/2020/05/nixos-tmpfs-as-root/#step-1-partitioning) for an understanding of how the general config works and how to mount the filesystems in a tmpfs as root setup
4. Mount the filesystems as specified in the article above
5. Connect to the internet: `sudo systemctl start wpa_supplicant` then `wpa_cli`
6. Run `nix-shell -p git nixFlakes`
7. Now that you are in an environment with git and flakes, clone this repository
8. Exit the nix shell with `exit` change into the cloned directory, and run `nix-shell`
9. Run `sudo git config --global --add safe.directory $(pwd)`
10. Run `sudo nixos-install --option pure-eval no --flake $FLAKE#farnsworth`
