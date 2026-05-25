{ config, inputs, lib, ... }:

{
  flake.deploy.nodes = lib.mapAttrs (name: cfg: {
    hostname = cfg.config.networking.fqdn;
    profiles.system = {
      user = "root";
      sshUser = "root";
      sshOpts = [ "-p" (builtins.toString (builtins.elemAt cfg.config.services.openssh.ports 0)) ];
      path = lib.pipe cfg [
        (c: c.pkgs.stdenv.targetPlatform.system)
        (arch: inputs.deploy-rs.lib.${arch}.activate.nixos or (throw "Unsupported architecture: ${arch}"))
        (activate: activate cfg)
      ];
    };
  }) config.flake.nixosConfigurations;
}
