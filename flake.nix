{
  description = "Will McKinnon's personal nix configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";

    nixos-hardware.url = github:NixOS/nixos-hardware/master;

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = github:nix-community/impermanence/master;

    nur = {
      url = github:nix-community/NUR/master;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    emacs-overlay.url  = "github:nix-community/emacs-overlay";
  };

  outputs = { nixpkgs, nixos-hardware, home-manager, impermanence, nur, emacs-overlay, ... }:
  let
    system = "x86_64-linux";
    lib = nixpkgs.lib;
    flake-overlays = [nur.overlay emacs-overlay.overlay];

  in {
    nixosConfigurations = {
      desktop = lib.nixosSystem {
        inherit system;
        modules = [ ./hosts/desktop ];
        specialArgs = { inherit impermanence home-manager flake-overlays; };
      };

      surface = lib.nixosSystem {
        inherit system;
        modules = [ ./hosts/surface ];
        specialArgs = { inherit nixos-hardware home-manager flake-overlays; };
      };
    };
  };
}
