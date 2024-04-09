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

    ags.url = "github:Aylur/ags";
    stylix.url = "github:danth/stylix";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs = { self, nixpkgs, home-manager, impermanence, deploy-rs, agenix, ags, stylix, nixos-hardware, ... }:
  let
    mkNixos = modules: nixpkgs.lib.nixosSystem {
      inherit modules;
      system = "x86_64-linux";
      specialArgs = { inherit nixpkgs impermanence home-manager agenix ags stylix nixos-hardware; };
    };

    mkHome = modules: pkgs: home-manager.lib.homeManagerConfiguration {
      inherit modules pkgs;
      extraSpecialArgs = { inherit impermanence ags stylix; };
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
      lighthouse = mkNixos [ ./hosts/lighthouse ];
      media-center = mkNixos [ ./hosts/media-center ];
      server = mkNixos [ ./hosts/server ];
      surface = mkNixos [ ./hosts/surface ];
    };

    homeConfigurations."will" = mkHome [ ./home ] nixpkgs.legacyPackages."x86_64-linux";

    # TODO: ex https://github.com/disassembler/network/blob/18e4d34b3d09826f1239772dc3c2e8c6376d5df6/nixos/deploy.nix
    deploy.nodes = {
      lighthouse = mkDeployTarget "143.110.232.34" self.nixosConfigurations.lighthouse;
      media-center = mkDeployTarget "10.27.27.6" self.nixosConfigurations.media-center;
      server = mkDeployTarget "10.27.27.3" self.nixosConfigurations.server;
    };
  };
}
