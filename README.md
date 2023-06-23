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
10. Run `sudo nixos-install --option pure-eval no --flake $FLAKE#desktop`

## Additional Steps for the Server Flake
1. Read "[Installing NixOS with root on tmpfs and encrypted ZFS on a netcup VPS](https://carjorvaz.com/posts/installing-nixos-with-root-on-tmpfs-and-encrypted-zfs-on-a-netcup-vps/)" for more insight on root on tmpfs + ZFS setup
2. Set up SSH access
  1. Set `services.openssh.settings.PermitRootLogin = "yes"` in the config
  2. Follow the instructions in the [NixOS wiki](https://nixos.wiki/wiki/SSH_public_key_authentication) to create an SSH key and copy it to the server
  3. Append the key to the `authorizedKeys` lists in the config
