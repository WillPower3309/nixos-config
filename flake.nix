{
  description = "Will McKinnon's personal nix configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = "github:nix-community/impermanence/master";
  };

  outputs = { nixpkgs, nixos-hardware, home-manager, impermanence, ... }:
  let
    mkNixos = modules: nixpkgs.lib.nixosSystem {
      inherit modules;
      system = "x86_64-linux";
      specialArgs = { inherit impermanence home-manager ; };
    };

    mkHome = modules: pkgs: home-manager.lib.homeManagerConfiguration {
      inherit modules pkgs;
      extraSpecialArgs = { inherit impermanence; };
    };

  in {
    nixosConfigurations = {
      desktop = mkNixos [ ./hosts/desktop ];
      server = mkNixos [ ./hosts/server ]; 
      surface = mkNixos [ ./hosts/surface ];
    };

    homeConfigurations = {
      "will" = mkHome [ ./home ] nixpkgs.legacyPackages."x86_64-linux";
    };
  };
}
