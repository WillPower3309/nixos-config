{ inputs, ... }:

let
  pkgs = inputs.nixpkgs.legacyPackages."x86_64-linux";
in {
  # CNI plugin that moves an SR-IOV VF into a container's netns, setting its MAC/VLAN on the PF
  flake.packages.x86_64-linux.sriov-cni = pkgs.buildGoModule rec {
    pname = "sriov-cni";
    version = "2.9.0";

    src = pkgs.fetchFromGitHub {
      owner = "k8snetworkplumbingwg";
      repo = "sriov-cni";
      rev = "v${version}";
      hash = "sha256-0kpYeSCPTTHnq1mcVdwavRMKb2DTrDp21CQRBBS6Yl8=";
    };

    vendorHash = "sha256-QHGt2TOiBhlkd1f3IrKxw02xzmYojOf73cyCXgWhHdg=";

    subPackages = [ "cmd/sriov" ];
    doCheck = false; # tests need netlink/sysfs access

    meta = {
      description = "SR-IOV CNI plugin";
      homepage = "https://github.com/k8snetworkplumbingwg/sriov-cni";
      license = pkgs.lib.licenses.asl20;
      mainProgram = "sriov";
    };
  };
}
