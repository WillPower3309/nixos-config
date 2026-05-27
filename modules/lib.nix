{ inputs, lib, ... }:

{
  options.flake.lib = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.unspecified;
  };

  config.flake.lib = {
    mkNixos = system: name: {
      ${name} = inputs.nixpkgs.lib.nixosSystem {
        modules = [
          inputs.self.modules.nixos.${name}
          { nixpkgs.hostPlatform = lib.mkDefault system; }
        ];
      };
    };

    mkHomeManager = system: name: {
      ${name} = inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = inputs.nixpkgs.legacyPackages.${system};
        modules = [
          # Stub so home.persistence definitions are accepted in standalone.
          # They won't do anything — the real module is auto-imported by the
          # NixOS impermanence module when HM runs inside a NixOS eval.
          { options.home.persistence = lib.mkOption { type = lib.types.attrsOf lib.types.unspecified; default = { }; }; }
          inputs.self.modules.homeManager.${name}
        ];
      };
    };
  };
}
