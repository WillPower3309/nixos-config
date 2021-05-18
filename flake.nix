{
  description = "Will McKinnon's personal nix configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-20.09";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  # overlay setup: https://github.com/dramforever/config/blob/2b3883db27e9587fc9e820873874e346260e6f4f/nixos/flake.nix
  
  outputs = { nixpkgs, home-manager, ... }:
  let
    system = "x86_64-linux";

    pkgs = import nixpkgs {
      inherit system;
      config = { allowUnfree = true; };
    };

    lib = nixpkgs.lib;

  in {
    nixosConfigurations = {
      farnsworth = lib.nixosSystem {
        inherit system;

	modules = [
	  ./configuration.nix
	];
      };
    };
  };
}
