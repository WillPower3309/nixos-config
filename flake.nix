# TODO: use github:vic/flake-file to generate this
{
  description = "Will McKinnon's personal nix configuration";

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } {
    # Import the flake-parts modules extra which declares flake.modules
    # with a mergeable type (lazyAttrsOf (lazyAttrsOf deferredModule))
    # so that import-tree's many submodules can each contribute
    # flake.modules.nixos.<name> without hitting the freeformType's
    # "unique raw" constraint.
    imports = [
      inputs.flake-parts.flakeModules.modules
      (inputs.import-tree ./modules)
    ];
  };

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";

    import-tree.url = "github:denful/import-tree";
    flake-parts.url = "github:hercules-ci/flake-parts";

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
}

