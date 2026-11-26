{ inputs, ... }:

let
  pkgs = inputs.nixpkgs.legacyPackages."x86_64-linux";
  name = "home-assistant";

  # update imageDigest from `nix run nixpkgs#nix-prefetch-docker -- --image-name ghcr.io/home-assistant/home-assistant --image-tag stable`,
  # then hash from the build's mismatch error (the archive includes the tag, so the prefetched hash won't match)
  image = pkgs.dockerTools.pullImage {
    imageName = "ghcr.io/home-assistant/home-assistant";
    imageDigest = "sha256:130241f28d01fa80dfa3b44f7d89781c188d8642ecab9024f079f19f9f82baa0";
    hash = "sha256-CQCZuj+UviNyFQf7d0CFehVlKD+D/etno5Gm0Z6gQFM=";
    finalImageTag = "stable";
  };
in {
  flake.modules.nixos.cluster.services.k3s.manifests.${name}.content = {
    apiVersion = "apps/v1";
    kind = "Deployment";
    metadata = {
      inherit name;
      namespace = "default";
    };
    spec = {
      replicas = 1;
      strategy.type = "Recreate"; # only one pod can use the hostPath state
      selector.matchLabels.app = name;
      template = {
        metadata.labels.app = name;
        spec = {
          containers = [{
            inherit name;
            # nix-snapshotter loads the image from the store path (in every node's closure via this manifest)
            image = "nix:0${image}";
            imagePullPolicy = "IfNotPresent";
            env = [{ name = "TZ"; value = "America/Toronto"; }];
            volumeMounts = [{ name = "config"; mountPath = "/config"; }];
          }];
          volumes = [{
            name = "config";
            hostPath = { path = "/var/lib/workloads/${name}"; type = "DirectoryOrCreate"; };
          }];
        };
      };
    };
  };
}
