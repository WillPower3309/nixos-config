{ inputs, lib, ... }:

let
  authorizedKey = builtins.readFile ../../features/ssh-client/id_ed25519.pub;
in
{
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "lighthouse";

  flake.modules.nixos.lighthouse = { config, pkgs, lib, ... }: {
    networking.hostName = "lighthouse";

    imports = with inputs.self.modules.nixos; [
      common
      ssh-server
    ] ++ [ inputs.agenix.nixosModules.age ];

    boot = {
      lanzaboote.enable = false;
      loader = {
        systemd-boot.enable = false;
        grub.devices = lib.mkForce [ "/dev/vda" ];
      };
    };

    networking.useDHCP = lib.mkForce false;

    # Based on https://github.com/canonical/cloud-init/blob/main/config/cloud.cfg.tmpl
    services.cloud-init = {
      enable = true;
      network.enable = true;
      settings = {
        datasource_list = [ "ConfigDrive" "Digitalocean" ];
        datasource.ConfigDrive = { };
        datasource.Digitalocean = { };
        cloud_init_modules = [
          "seed_random" "bootcmd" "write_files" "growpart" "resizefs"
          "set_hostname" "update_hostname" "set_password"
        ];
        cloud_config_modules = [
          "ssh-import-id" "keyboard" "runcmd" "disable_ec2_metadata"
        ];
        cloud_final_modules = [
          "write_files_deferred" "puppet" "chef" "ansible" "mcollective"
          "salt_minion" "reset_rmc" "scripts_per_once" "scripts_per_boot"
          "scripts_user" "ssh_authkey_fingerprints" "keys_to_console"
          "install_hotplug" "phone_home" "final_message"
        ];
      };
    };

    age.secrets = {
      nebulaCaCert = {
        file = "${inputs.secrets}/nebulaCaCert.age";
        owner = "nebula-home";
        group = "nebula-home";
      };
      lighthouseNebulaCert = {
        file = "${inputs.secrets}/lighthouseNebulaCert.age";
        owner = "nebula-home";
        group = "nebula-home";
      };
      lighthouseNebulaKey = {
        file = "${inputs.secrets}/lighthouseNebulaKey.age";
        owner = "nebula-home";
        group = "nebula-home";
      };
    };

    networking.firewall = {
      allowedUDPPorts = [ 4242 ];
      allowedTCPPorts = [ 32400 ];
    };

    users = {
      users.root.openssh.authorizedKeys.keys = [
        authorizedKey
        (builtins.readFile ../../../modules/hosts/server/ssh_host_ed25519_key.pub)
      ];
      mutableUsers = false;
    };

    services = {
      openssh = {
        ports = lib.mkForce [ 2222 ];
        settings.GatewayPorts = "yes";
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
          overalljails = true;
        };
      };
    };

    # TODO: why is this rsa?
    environment.etc."ssh/ssh_host_ed25519_key.pub".source = ./ssh_host_ed25519_key.pub;
  };
}
