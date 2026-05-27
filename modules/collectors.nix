{ inputs, config, lib, ... }:

{
  flake.deploy.nodes = lib.mapAttrs (name: cfg: {
    hostname = cfg.config.networking.fqdn;
    profiles.system = {
      user = "root";
      sshUser = "root";
      sshOpts = [ "-p" (builtins.toString (builtins.elemAt cfg.config.services.openssh.ports 0)) ];
      path = lib.pipe cfg [
        (c: c.pkgs.targetPlatform.system)
        (arch: inputs.deploy-rs.lib.${arch}.activate.nixos or (throw "Unsupported architecture: ${arch}"))
        (activate: activate cfg)
      ];
    };
  }) config.flake.nixosConfigurations;

  flake.checks = lib.recursiveUpdate
    (builtins.mapAttrs (_: deployLib: deployLib.deployChecks config.flake.deploy) inputs.deploy-rs.lib)
    {
      x86_64-linux = builtins.mapAttrs
        (name: _: config.flake.homeConfigurations.${name}.activationPackage)
        config.flake.homeConfigurations;
    };
}
