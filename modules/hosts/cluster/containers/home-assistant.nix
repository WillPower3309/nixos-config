{ inputs, lib, ... }:

let
  pkgs = inputs.nixpkgs.legacyPackages."x86_64-linux";
  name = "home-assistant";
  port = 8123;
  stateDir = "/var/lib/workloads/${name}";

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
          # pinned to node0: the state lives on node0's disk (until ceph)
          affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms = [{
            matchExpressions = [{
              key = "kubernetes.io/hostname";
              operator = "In";
              values = [ "node0" ];
            }];
          }];
          containers = [{
            inherit name;
            # nix-snapshotter loads the image from the store path (in every node's closure via this manifest)
            image = "nix:0${image}";
            imagePullPolicy = "IfNotPresent";
            ports = [{ containerPort = port; }];
            env = [{ name = "TZ"; value = "America/Toronto"; }];
            volumeMounts = [{ name = "config"; mountPath = "/config"; }];
          }];
          volumes = [
            { name = "config"; hostPath = { path = stateDir; type = "DirectoryOrCreate"; }; }
          ];
        };
      };
    };
  };

  # LAN ingress via k3s's built-in traefik; every *.willmckinnon.com name resolves to the floating VIP.
  flake.modules.nixos.cluster.services.k3s.manifests."${name}-service".content = {
    apiVersion = "v1";
    kind = "Service";
    metadata = { inherit name; namespace = "default"; };
    spec = {
      selector.app = name; # matches the Deployment's pod labels
      ports = [{ inherit port; targetPort = port; }];
    };
  };

  flake.modules.nixos.cluster.services.k3s.manifests."${name}-ingress".content = {
    apiVersion = "traefik.io/v1alpha1";
    kind = "IngressRoute";
    metadata = { inherit name; namespace = "default"; };
    spec = {
      entryPoints = [ "web" ];
      routes = [{
        kind = "Rule";
        match = "Host(\`${name}.willmckinnon.com\`)"; # config.constants.domain
        services = [{ inherit name port; }];
      }];
    };
  };
}
