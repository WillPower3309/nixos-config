{ config, inputs, lib, ... }:

let
  # https://developer.hashicorp.com/nomad/docs/job-specification/constraint
  constraintType = lib.types.submodule {
    options = {
      attribute = lib.mkOption { type = lib.types.str; };
      operator = lib.mkOption {
        type = lib.types.str;
        default = "=";
      };
      value = lib.mkOption {
        type = lib.types.str;
        default = "";
      };
    };
  };

  microvmType = lib.types.submodule {
    options = {
      nomad.constraints = lib.mkOption {
        type = lib.types.listOf constraintType;
        default = [];
        example = [{ attribute = "\${node.unique.name}"; value = "node0"; }];
      };
    };
  };
in {
  # microvms defined in modules/vms/, keyed by the name of their flake.modules.nixos entry
  options.flake.microvms = lib.mkOption {
    type = lib.types.lazyAttrsOf microvmType;
    default = {};
  };

  config.flake.packages = lib.mkMerge (lib.mapAttrsToList (name: _: {
    x86_64-linux."${name}-vm" = inputs.self.lib.mkMicrovmPackage "x86_64-linux" name;
  }) config.flake.microvms);
}
