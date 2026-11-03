{ inputs, ... }:

let
  pkgs = inputs.nixpkgs.legacyPackages."x86_64-linux";
in {
  # kubelet device plugin that advertises SR-IOV VFs as a schedulable resource, which multus then hands to sriov-cni
  flake.packages.x86_64-linux.sriov-network-device-plugin = pkgs.buildGoModule rec {
    pname = "sriov-network-device-plugin";
    version = "3.11.0";

    src = pkgs.fetchFromGitHub {
      owner = "k8snetworkplumbingwg";
      repo = "sriov-network-device-plugin";
      rev = "v${version}";
      hash = "sha256-I0yn2zEMNpF/itV4CTPtwaJstuiepNl/XVRzSu6JLpU=";
    };

    vendorHash = "sha256-W8/duC8x8uWR16r/SKEZ3Y/T3fIHWXpe9WEd0h+yiLI=";

    subPackages = [ "cmd/sriovdp" ];
    doCheck = false; # tests need sysfs access

    meta = {
      description = "SR-IOV network device plugin for Kubernetes";
      homepage = "https://github.com/k8snetworkplumbingwg/sriov-network-device-plugin";
      license = pkgs.lib.licenses.asl20;
      mainProgram = "sriovdp";
    };
  };
}
