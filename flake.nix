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

    proxmox-nixos = {
      url = "github:SaumonNet/proxmox-nixos";
      inputs.nixpkgs-unstable.follows = "nixpkgs";
    };

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rapidshell = {
      url = "github:willpower3309/rapidshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs = { self, nixpkgs, home-manager, impermanence, deploy-rs, agenix, disko, nixos-generators, nixos-hardware, proxmox-nixos, rapidshell, ... }:
  let
    mkNixos = modules: nixpkgs.lib.nixosSystem {
      inherit modules;
      system = "x86_64-linux";
      specialArgs = { inherit nixpkgs impermanence home-manager agenix disko nixos-hardware proxmox-nixos rapidshell; };
    };

    mkHome = modules: pkgs: home-manager.lib.homeManagerConfiguration {
      inherit modules pkgs;
      extraSpecialArgs = { inherit impermanence agenix rapidshell; };
    };

    mkImage = format: modules: nixos-generators.nixosGenerate {
      inherit format modules;
      system = "x86_64-linux";
    };

    mkDeployTarget = hostname: configPath: {
      hostname = hostname;
      profiles.system = {
        user = "root";
        sshUser = "root";
        path = deploy-rs.lib.x86_64-linux.activate.nixos configPath;
      };
    };

  in {
    nixosConfigurations = {
      desktop = mkNixos [ ./hosts/desktop ];
      laptop = mkNixos [ ./hosts/laptop ];
      lighthouse = mkNixos [ ./hosts/lighthouse ];
      server = mkNixos [ ./hosts/server ];
      router = mkNixos [ ./hosts/router ];
      proxmox = mkNixos [ ./hosts/proxmox ];
      # TODO: support arm in mkNixos
      tv = nixpkgs.lib.nixosSystem {
        modules = [ ./hosts/tv ];
        system = "aarch64-linux";
        specialArgs = { inherit nixpkgs nixos-hardware impermanence home-manager disko; };
      };
    };

    homeConfigurations."will" = mkHome [ ./home ] nixpkgs.legacyPackages."x86_64-linux";

    packages.x86_64-linux.installationMedia = mkImage "install-iso" [ ./images/installation-media.nix ];

    # TODO: ex https://github.com/disassembler/network/blob/18e4d34b3d09826f1239772dc3c2e8c6376d5df6/nixos/deploy.nix
    deploy.nodes = {
      lighthouse = {
        hostname = "lighthouse.willmckinnon.com";
        profiles.system = {
          user = "root";
          sshUser = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.lighthouse;
          sshOpts = [ "-p" "2222" ];
        };
      };
      server = mkDeployTarget "server.willmckinnon.com" self.nixosConfigurations.server;
      router = mkDeployTarget "10.27.27.1" self.nixosConfigurations.router;
      proxmox = mkDeployTarget "10.27.27.10" self.nixosConfigurations.proxmox;
      tv = {
        hostname = "192.168.1.172";
        profiles.system = {
          user = "root";
          sshUser = "root";
          path = deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.tv;
        };
      };
    };
  };
}
