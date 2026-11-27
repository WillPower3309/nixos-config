{ inputs, lib, ... }:

let
  pkgs = inputs.nixpkgs.legacyPackages."x86_64-linux";
  name = "unifi-os";
  port = 443; # unifi-os serves a self-signed cert (CN=unifi.local)
  stateDir = "/var/lib/workloads/${name}";

  # Ubiquiti only ships the image inside its installer, use lemker's repackaging
  # update imageDigest (with the tag) from `skopeo inspect docker://ghcr.io/lemker/unifi-os-server:<tag>`,
  # then hash from the build's mismatch error
  image = pkgs.dockerTools.pullImage {
    imageName = "ghcr.io/lemker/unifi-os-server";
    imageDigest = "sha256:c0136d42d238b9574d93676aada3f61971ffb6bcbe2a3050627a9fa7ced7c878";
    hash = "sha256-UTntYDj28k/EGHcBqW1j+QvTtvE9AiQN633Dwm3nQ7M=";
    finalImageTag = "v1.8.0";
  };

  # container path -> subdirectory of stateDir (named as the unifi-os-server module did, so old state copies over 1:1)
  state = {
    "/persistent" = "persistent";
    "/var/log" = "log";
    "/data" = "data";
    "/srv" = "srv";
    "/var/lib/unifi" = "unifi";
    "/var/lib/mongodb" = "mongodb";
    "/etc/rabbitmq/ssl" = "rabbitmq-ssl";
  };

  # what the image expects as tmpfs, for systemd and unifi
  tmpfs = [ "/run" "/tmp" "/var/lib/journal" "/var/opt/unifi/tmp" ];
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

          # the image stops systemd with its STOPSIGNAL; give the services time to shut down
          terminationGracePeriodSeconds = 95;

          containers = [{
            inherit name;
            # nix-snapshotter loads the image from the store path (in every node's closure via this manifest)
            image = "nix:0${image}";
            imagePullPolicy = "IfNotPresent";
            # systemd runs as PID 1 and needs a writable cgroup tree
            securityContext.privileged = true;
            env = [{ name = "TZ"; value = "America/Toronto"; }];
            # one volume each for state and tmpfs, with a subPath per mount (kubelet creates missing subdirectories)
            volumeMounts = lib.mapAttrsToList (path: subPath: { name = "state"; mountPath = path; inherit subPath; }) state
              ++ map (path: { name = "tmpfs"; mountPath = path; subPath = lib.removePrefix "/" path; }) tmpfs;
          }];

          volumes = [
            { name = "state"; hostPath = { path = stateDir; type = "DirectoryOrCreate"; }; }
            { name = "tmpfs"; emptyDir.medium = "Memory"; }
          ];
        };
      };
    };
  };

  # LAN ingress via k3s's built-in traefik; every *.willmckinnon.com name resolves to the floating VIP.
  # The route speaks HTTPS upstream and skips certificate verification (self-signed cert, CN=unifi.local)
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
        services = [{
          inherit name port;
          scheme = "https";
          serversTransport = name;
        }];
      }];
    };
  };

  flake.modules.nixos.cluster.services.k3s.manifests."${name}-servers-transport".content = {
    apiVersion = "traefik.io/v1alpha1";
    kind = "ServersTransport";
    metadata = { inherit name; namespace = "default"; };
    spec = { insecureSkipVerify = true; };
  };
}
