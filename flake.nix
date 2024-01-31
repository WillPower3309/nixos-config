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
  };

  outputs = { self, nixpkgs, home-manager, impermanence, deploy-rs, agenix, ... }:
  let
    mkNixos = modules: nixpkgs.lib.nixosSystem {
      inherit modules;
      system = "x86_64-linux";
      specialArgs = { inherit nixpkgs impermanence home-manager agenix; };
    };

    mkHome = modules: pkgs: home-manager.lib.homeManagerConfiguration {
      inherit modules pkgs;
      extraSpecialArgs = { inherit impermanence; };
    };

  in {
    nixosConfigurations = {
      desktop = mkNixos [ ./hosts/desktop ];
      lighthouse = mkNixos [ ./hosts/lighthouse ];
      server = mkNixos [ ./hosts/server ];
      surface = mkNixos [ ./hosts/surface ];
    };

    homeConfigurations."will" = mkHome [ ./home ] nixpkgs.legacyPackages."x86_64-linux";

    # TODO: ex https://github.com/disassembler/network/blob/18e4d34b3d09826f1239772dc3c2e8c6376d5df6/nixos/deploy.nix
    deploy.nodes = {
      server = {
        hostname = "10.27.27.3";
        profiles.system = {
          user = "root";
          sshUser = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.server;
        };
      };
      lighthouse = {
        hostname = "143.110.232.34";
        profiles.system = {
          user = "root";
          sshUser = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.lighthouse;
        };
      };
    };
  };
}
