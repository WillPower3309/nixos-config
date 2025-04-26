# nixos-config
My personal nixos config

## Installation

### Generic x86 (remote installation)

1. Build the nixos installation image: `nix build .#packages.x86_64-linux.installationMedia`
2. Flash the image to a USB stick
3. Boot nixos through the installation media and note its IP address
4. Generate a key pair for the given host, and move the public key to the host's folder
5. Remotely install nixos and send the private key to the new host via: ``

### Raspberry Pi
1. Generate a key pair for the given host, and move the public key to the host's folder
2. Build the disko image script: `nix build .#nixosConfigurations.<HOST_NAME>.config.system.build.diskoImagesScript`
3. Execute the disko image script, and add the host's private key: `sudo ./result --post-format-files <PATH_TO_PRIVATE_KEY> persist/etc/ssh/ssh_host_ed25519_key`
4. Flash the image to an SD card, and insert the SD card into the pi

