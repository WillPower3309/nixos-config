{
  description = "Will McKinnon's personal nix configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = "github:nix-community/impermanence";

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    proxmox-nixos.url = "github:SaumonNet/proxmox-nixos";

    pinenote-nixos = {
      url = "github:WeraPea/pinenote-nixos";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rapidshell = {
      url = "github:willpower3309/rapidshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote"; # TODO: use next stable release
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs = { self, nixpkgs, deploy-rs, ... }@inputs:
  let
    lib = nixpkgs.lib;

    hostNames = lib.pipe ./hosts [
      builtins.readDir
      (lib.filterAttrs (name: type: type == "directory"))
      builtins.attrNames
    ];

  in {
    # TODO: pass network config of all hosts down to router, ssh client, etc
    nixosConfigurations = lib.genAttrs hostNames (name: lib.nixosSystem {
      system = "x86_64-linux"; # overridden in host module otherwise
      modules = [
        { networking.hostName = lib.mkForce name; }
        ./hosts/${name}
        ./modules/common
        # TODO: add modules/features?
      ];
      specialArgs = { inherit inputs; };
    });

    # TODO: dedicated deployment port and user?
    # TODO: all should be dynamic
    deploy.nodes = {
      router-legacy = {
        hostname = "10.1.10.1";
        profiles.system = {
          user = "root";
          sshUser = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.router;
        };
      };
      server-legacy = {
        hostname = "10.1.10.6";
        profiles.system = {
          user = "root";
          sshUser = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.server;
        };
      };
      proxmox-legacy = {
        hostname = "10.1.10.3";
        profiles.system = {
          user = "root";
          sshUser = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.proxmox;
        };
      };
    } // (lib.mapAttrs (name: cfg: {
      hostname = cfg.config.networking.fqdn;
      profiles.system = {
        user = "root";
        sshUser = "root";
        sshOpts = [ "-p" builtins.toString (builtins.elemAt cfg.config.services.openssh.ports 0) ];
        path = lib.pipe cfg [
          (c: c.pkgs.targetPlatform.system)
          (arch: deploy-rs.lib.${arch}.activate.nixos or (throw "Unsupported architecture: ${arch}"))
          (activate: activate cfg)
        ];
      };
    }) self.nixosConfigurations);
  };
}

