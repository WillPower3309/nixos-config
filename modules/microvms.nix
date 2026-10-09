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

  vfType = lib.types.submodule {
    options = {
      mac = lib.mkOption {
        type = lib.types.str;
        description = "MAC address the host sets on the VF (the guest can't change it)";
      };
      vlan = lib.mkOption {
        type = lib.types.nullOr (lib.types.ints.between 1 4094);
        default = null;
        description = "port VLAN the NIC tags/untags in hardware, confining the guest to it. null leaves the VF on the raw trunk, where the guest can tag any VLAN";
      };
    };
  };

  microvmType = lib.types.submodule {
    options = {
      vfs = lib.mkOption {
        type = lib.types.listOf vfType;
        default = [];
        description = "SR-IOV VFs passed through as the VM's NICs, in order (see modules/hosts/server-cluster/nomad-job.nix)";
      };

      nomad.constraints = lib.mkOption {
        type = lib.types.listOf constraintType;
        default = [];
        example = [{ attribute = "\${node.unique.name}"; value = "node0"; }];
      };
    };
  };
in {
  options.flake.microvms = lib.mkOption {
    type = lib.types.lazyAttrsOf microvmType;
    default = {};
  };

  config.flake.packages = lib.mkMerge (lib.mapAttrsToList (name: _: {
    x86_64-linux."${name}-vm" = inputs.self.lib.mkMicrovmPackage "x86_64-linux" name;
  }) config.flake.microvms);
}
