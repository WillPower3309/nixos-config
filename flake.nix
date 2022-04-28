{
  description = "Will McKinnon's personal nix configuration";

  inputs = {
    # Core dependencies
    nixpkgs.url = "nixpkgs/nixos-21.11";
    nixos.url = "nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixos";
    };
    impermanence.url = github:nix-community/impermanence/master;

    nur.url = github:nix-community/NUR/master;
    emacs-overlay.url  = "github:nix-community/emacs-overlay";
  };

  outputs = { nixpkgs, home-manager, nur, emacs-overlay, impermanence, ... }:
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

	  impermanence.nixosModules.impermanence
	  {
	    environment.persistence."/nix/persist" = import ./persistence.nix;
	  }

	  home-manager.nixosModules.home-manager {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.will = import ./home.nix;
      }

	  {
        nixpkgs.overlays = [
          nur.overlay
          emacs-overlay.overlay
        ];
      }
	];
      };
    };
  };
}
