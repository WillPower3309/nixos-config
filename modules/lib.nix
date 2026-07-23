{ inputs, lib, ... }:

{
  options.flake.lib = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.unspecified;
  };

  config.flake.lib = {
    mkNixos = system: name: {
      ${name} = inputs.nixpkgs.lib.nixosSystem {
        modules = [
          { nixpkgs.hostPlatform = system; }
          inputs.self.modules.nixos.${name}
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
          inputs.self.constants
          inputs.self.modules.homeManager.${name}
        ];
      };
    };

    mkMicrovmPackage = system: name: (inputs.self.lib.mkNixos system name).${name}.config.microvm.runner.qemu;
  };
}
