{ config, modulesPath, lib, pkgs, nixpkgs, agenix, impermanence, ... }:

let
  authorizedKey = (builtins.readFile ../../home/id_ed25519.pub);
  hostKeyPath = /etc/ssh/ssh_host_ed25519_key;

in
{
  imports = [
    "${modulesPath}/virtualisation/digital-ocean-config.nix"
    agenix.nixosModules.default
    impermanence.nixosModules.impermanence
    ./disks.nix
    ../../modules/nix.nix
  ];

  # fixes duplicated devices in mirroredBoots
  boot.loader.grub.devices = lib.mkForce ["/dev/vda"];

  # do not use DHCP, as DigitalOcean provisions IPs using cloud-init
  networking.useDHCP = lib.mkForce false;

  # Disables all modules that do not work with NixOS
  services.cloud-init = {
    enable = true;
    network.enable = true;
    settings = {
      datasource_list = [
        "ConfigDrive"
        "Digitalocean"
      ];
      datasource.ConfigDrive = { };
      datasource.Digitalocean = { };
      # Based on https://github.com/canonical/cloud-init/blob/main/config/cloud.cfg.tmpl
      cloud_init_modules = [
        "seed_random"
        "bootcmd"
        "write_files"
        "growpart"
        "resizefs"
        "set_hostname"
        "update_hostname"
        # Not support on NixOS
        #"update_etc_hosts"
        # throws error
        #"users-groups"
        # tries to edit /etc/ssh/sshd_config
        #"ssh"
        "set_password"
      ];
      cloud_config_modules = [
        "ssh-import-id"
        "keyboard"
        # doesn't work with nixos
        #"locale"
        "runcmd"
        "disable_ec2_metadata"
      ];
      ## The modules that run in the 'final' stage
      cloud_final_modules = [
        "write_files_deferred"
        "puppet"
        "chef"
        "ansible"
        "mcollective"
        "salt_minion"
        "reset_rmc"
        # install dotty agent fails
        #"scripts_vendor"
        "scripts_per_once"
        "scripts_per_boot"
        # /var/lib/cloud/scripts/per-instance/machine_id.sh has broken shebang
        #"scripts_per_instance"
        "scripts_user"
        "ssh_authkey_fingerprints"
        "keys_to_console"
        "install_hotplug"
        "phone_home"
        "final_message"
      ];
    };
  };

  # TODO: cr in nixpkgs to add option for setting nebula user / group
  age.secrets = {
    nebulaCaCert = {
      file = ../../secrets/nebulaCaCert.age;
      owner = "nebula-home";
      group = "nebula-home";
    };
    lighthouseNebulaCert = {
      file = ../../secrets/lighthouseNebulaCert.age;
      owner = "nebula-home";
      group = "nebula-home";
    };
    lighthouseNebulaKey = {
      file = ../../secrets/lighthouseNebulaKey.age;
      owner = "nebula-home";
      group = "nebula-home";
    };
  };

  networking.firewall = {
    allowedUDPPorts = [ 4242 ]; # nebula
    allowedTCPPorts = [ 32400 ]; # plex ssh tunnel
  };

  users = {
    users.root.openssh.authorizedKeys.keys = [
      authorizedKey
      (builtins.readFile ../server/ssh_host_ed25519_key.pub)
    ];
    mutableUsers = false;
  };

  services = {
    openssh = {
      enable = true;
      ports = [ 2222 ];
      openFirewall = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        GatewayPorts = "yes"; # for plex ssh tunnel
      };
      hostKeys = [{
        path = "/nix/persist${(toString hostKeyPath)}";
        type = "ed25519";
      }];
    };

    nebula.networks.home = {
      enable = true;
      isLighthouse = true;
      isRelay = true;
      cert = config.age.secrets.lighthouseNebulaCert.path; # lighthouse.crt
      key = config.age.secrets.lighthouseNebulaKey.path; # lighthouse.key
      ca = config.age.secrets.nebulaCaCert.path; # ca.crt
    };

    fail2ban = {
      enable = true;
      maxretry = 2;
      bantime = "24h";
      bantime-increment = {
        enable = true;
        multipliers = "1 2 4 8 16 32 64";
        overalljails = true; # Calculate the bantime based on all the violations
      };
    };
  };

  # Set your time zone.
  time.timeZone = "America/Toronto";

  environment = {
    persistence."/nix/persist" = {
      hideMounts = true;
      directories = [
        "/var/log"
        "/var/lib/nixos"
      ];
      files = [ (toString hostKeyPath) ];
    };

    etc."ssh/ssh_host_ed25519_key.pub".source = ./ssh_host_ed25519_key.pub;
  };

  system.stateVersion = config.system.nixos.release;
}

