# nixos-config
My personal nixos config

## Installation

### Generic x86 (remote installation)

1. Build the nixos installation image: `nix build .#packages.x86_64-linux.installationMedia`
2. Flash the image to a USB stick
3. Boot nixos through the installation media and note its IP address
4. Generate a key pair for the given host, and move the public key to a tmp directory:
```
root=$(mktemp -d)
mkdir -p ${root}/nix/persist/etc/ssh
cp <PATH TO SYSTEM PRIVATE KEY> ${root}/nix/persist/etc/ssh
cp ~/.ssh/id_ed25519 ${root}/nix/persist/home/will/.ssh
```
5. Remotely install nixos and send the private key to the new host:
```
nix run github:nix-community/nixos-anywhere -- --extra-files ${root} --flake .#<CONFIG_NAME> --target-host root@<INSTALLATION_TARGET_IP_ADDRESS>
```

### Raspberry Pi
1. Generate a key pair for the given host, and move the public key to the host's folder
2. Build the disko image script: `nix build .#nixosConfigurations.<HOST_NAME>.config.system.build.diskoImagesScript`
3. Execute the disko image script, and add the host's private key: `sudo ./result --post-format-files <PATH_TO_PRIVATE_KEY> persist/etc/ssh/ssh_host_ed25519_key`
4. Flash the image to an SD card, and insert the SD card into the pi

### TV
Haven't yet had the patience to set up addons and settings with nix. Addons used include:
+ https://github.com/croneter/PlexKodiConnect
  + will likely need to `chmod +w` the `.kodi/userdata/library/video/` directory

## Managed Switch Setup
The default IP of the switch is `192.168.0.1`. To configure the switch (and move it to the proper subnet, perform the following steps:
1. Give the client a static IP on the same subnet: `sudo ip addr add 192.168.0.2 dev <interface name>`
2. Remove the old interface IP address (if it had one): `sudo ip addr delete <previous ip>/32 dev <interface name>`
3. Add a route to the switch: `sudo ip route add 192.168.0.1 dev <interface name>`

