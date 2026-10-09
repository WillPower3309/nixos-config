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

  proxyType = lib.types.submodule {
    options = {
      port = lib.mkOption { type = lib.types.port; };
      scheme = lib.mkOption {
        type = lib.types.enum [ "http" "https" ];
        default = "http";
        description = "protocol the VM serves on port (https upstream certificates aren't verified)";
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

      proxy = lib.mkOption {
        type = lib.types.attrsOf proxyType;
        default = {};
        example = { ha.port = 8123; };
        description = "services the reverse-proxy VM serves as <name>.<domain>, proxied to the VM's first NIC. Names can't be reservation hostnames, which resolve to the machine (asserted by the router)";
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
