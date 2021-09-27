{
  description = "Will McKinnon's personal nix configuration";

  inputs = {
    nixos.url = "nixpkgs/nixos-unstable";
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixos";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
  let
    system = "x86_64-linux";

    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };

    lib = nixpkgs.lib;

  in {
    nixosConfigurations = {
      farnsworth = lib.nixosSystem {
        inherit system;

	modules = [
	  ./configuration.nix
	  
	  home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.will = import ./home.nix;
          }

	  { nixpkgs.overlays = (import ./overlays/init.nix); }
	];
      };
    };
  };
}
