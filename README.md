# nixos-config
My personal nixos config

## Features
- **Secrets** are managed through [agenix](https://github.com/ryantm/agenix). The `./secrets.nix` file is located in the repository root, and iterates through the nixos and home-manager configurations to dynamically generate the path and public keys associated with each `.age` file across the repository
- **Deployments** are performed with [deploy-rs](https://github.com/serokell/deploy-rs). This configuration is dynamically generated for all hosts in `./modules/deploy.nix`

## Installation

### Generic x86 (remote installation)
1. Boot nixos through the installation media and note its IP address
2. Generate a key pair for the given host, and move the public key to a tmp directory:
```
root=$(mktemp -d)
mkdir -p ${root}/nix/persist/etc/ssh
cp <PATH TO SYSTEM PRIVATE KEY> ${root}/nix/persist/etc/ssh
```
    a. if on a system that uses the user "will": `cp ~/.ssh/id_ed25519 ${root}/nix/persist/home/will/.ssh`
3. Rekey secrets
4. Remotely install nixos and send the private key to the new host:
```
nix run github:nix-community/nixos-anywhere -- --extra-files ${root} --flake .#<CONFIG_NAME> --target-host root@<INSTALLATION_TARGET_IP_ADDRESS>
```
5. Boot the new host and run `sudo nix run nixpkgs#sbctl verify` to validate the host is ready for secure boot
6. Enable secure boot in the BIOS

### Raspberry Pi
1. Generate a key pair for the given host, and move the public key to the host's folder
2. Build the disko image script: `nix build .#nixosConfigurations.<HOST_NAME>.config.system.build.diskoImagesScript`
3. Execute the disko image script, and add the host's private key: `sudo ./result --post-format-files <PATH_TO_PRIVATE_KEY> persist/etc/ssh/ssh_host_ed25519_key`
4. Flash the image to an SD card, and insert the SD card into the pi
