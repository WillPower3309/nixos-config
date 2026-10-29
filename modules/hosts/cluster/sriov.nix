{ inputs, lib, ... }:

let
  dataDir = "/var/lib/rancher/k3s";
  cniConfDir = "${dataDir}/agent/etc/cni/net.d";
  cniBinDir = "${dataDir}/data/cni"; # k3s keeps non-k3s plugins dropped here across upgrades
  vfResource = "intel.com/sriov_lan"; # the device plugin's default "intel.com" prefix + resourceName below
  vlan = 10;
  gateway = "10.1.${toString vlan}.1";

  # from multus' deployments/multus-daemonset.yml
  networkAttachmentDefinitionCrd = {
    apiVersion = "apiextensions.k8s.io/v1";
    kind = "CustomResourceDefinition";
    metadata.name = "network-attachment-definitions.k8s.cni.cncf.io";
    spec = {
      group = "k8s.cni.cncf.io";
      scope = "Namespaced";
      names = {
        plural = "network-attachment-definitions";
        singular = "network-attachment-definition";
        kind = "NetworkAttachmentDefinition";
        shortNames = [ "net-attach-def" ];
      };
      versions = [{
        name = "v1";
        served = true;
        storage = true;
        schema.openAPIV3Schema = {
          type = "object";
          properties = {
            apiVersion.type = "string";
            kind.type = "string";
            metadata.type = "object";
            spec = {
              type = "object";
              properties.config.type = "string";
            };
          };
        };
      }];
    };
  };
in {
  # Manifests for a single-instance pod whose only network is an SR-IOV VF on the LAN, with the given MAC and
  # address (give it a network reservation). pod is a PodSpec; the first container is given the VF.
  # Its NetworkAttachmentDefinition is the pod's default network in place of flannel. Multus reads the VF the
  # device plugin allocated to the pod and hands it to sriov-cni, which sets the MAC and VLAN on the PF and
  # moves the VF into the pod's netns.
  flake.lib.mkSriovPod = { name, mac, address, pod }: [
    {
      apiVersion = "k8s.cni.cncf.io/v1";
      kind = "NetworkAttachmentDefinition";
      metadata = {
        inherit name;
        namespace = "default";
        annotations."k8s.v1.cni.cncf.io/resourceName" = vfResource;
      };
      spec.config = builtins.toJSON {
        cniVersion = "1.0.0";
        inherit name vlan;
        type = "sriov";
        spoofchk = "on";
        trust = "off";
        # sriov-cni only takes the MAC from runtimeConfig; libcni leaves it alone since no capabilities are declared
        runtimeConfig.mac = mac;
        ipam = {
          type = "static";
          addresses = [{ address = "${address}/24"; inherit gateway; }];
          routes = [{ dst = "0.0.0.0/0"; }];
        };
      };
    }
    {
      apiVersion = "apps/v1";
      kind = "Deployment";
      metadata = {
        inherit name;
        namespace = "default";
      };
      spec = {
        replicas = 1;
        strategy.type = "Recreate"; # two pods can't share the MAC/address or the hostPath state
        selector.matchLabels.app = name;
        template = {
          metadata = {
            labels.app = name;
            annotations."v1.multus-cni.io/default-network" = "default/${name}";
          };
          spec = pod // {
            # the pod has no cluster network, so no cluster DNS either
            dnsPolicy = "None";
            dnsConfig.nameservers = [ gateway ];
            containers = lib.imap0 (idx: container:
              if idx == 0 then lib.recursiveUpdate container { resources.limits.${vfResource} = 1; } else container
            ) pod.containers;
          };
        };
      };
    }
  ];

  flake.modules.nixos.cluster = { pkgs, ... }:
    let
      # thin multus in front of k3s' flannel: pods use flannel unless annotated with another default network
      multusConf = pkgs.writeText "00-multus.conf" (builtins.toJSON {
        cniVersion = "1.0.0";
        name = "multus-cni-network";
        type = "multus";
        kubeconfig = "/etc/rancher/k3s/k3s.yaml"; # every node is a server, so the admin kubeconfig is always present
        clusterNetwork = "${cniConfDir}/10-flannel.conflist";
      });

      devicePluginConf = pkgs.writeText "sriovdp-config.json" (builtins.toJSON {
        resourceList = [{
          resourceName = lib.removePrefix "intel.com/" vfResource;
          selectors = [{ drivers = [ "iavf" ]; }]; # every iavf-bound VF on the node is for pods
        }];
      });
    in {
      services.k3s.manifests.network-attachment-definitions.content = networkAttachmentDefinitionCrd;

      # 00- sorts before k3s' 10-flannel.conflist, so containerd uses multus
      systemd.tmpfiles.settings."10-sriov-cni" = {
        "${cniConfDir}/00-multus.conf"."L+".argument = "${multusConf}";
        "${cniBinDir}/multus"."L+".argument = "${pkgs.multus-cni}/bin/multus";
        "${cniBinDir}/sriov"."L+".argument = lib.getExe inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.sriov-cni;
        "${cniBinDir}/static"."L+".argument = "${pkgs.cni-plugins}/bin/static";
      };

      systemd.services.sriov-device-plugin = {
        description = "SR-IOV network device plugin";
        after = [ "k3s.service" ];
        bindsTo = [ "k3s.service" ];
        wantedBy = [ "k3s.service" ];
        serviceConfig = {
          ExecStart = "${lib.getExe inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.sriov-network-device-plugin} --config-file ${devicePluginConf}";
          Restart = "always";
          RestartSec = 5;
        };
      };
    };
}
