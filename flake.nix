{
  description = "Will McKinnon's personal nix configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-21.11";

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

  outputs = { nixpkgs, home-manager, impermanence, nur, emacs-overlay, ... }:
  let
    system = "x86_64-linux";
    lib = nixpkgs.lib;

  in {
    nixosConfigurations = {
      desktop = lib.nixosSystem {
        inherit system;

        modules = [
          ./hosts/desktop
          {
            nixpkgs.overlays = [
              nur.overlay
              emacs-overlay.overlay
            ];
          }
        ];

        specialArgs = { inherit impermanence home-manager; };
      };

      surface = lib.nixosSystem {
        inherit system;

        modules = [
          #nixos-hardware.nixosModules.microsoft-surface
          ./hosts/surface
          {
            nixpkgs.overlays = [
              nur.overlay
              emacs-overlay.overlay
            ];
          }
        ];
        specialArgs = { inherit home-manager; };
      };
    };
  };
}
