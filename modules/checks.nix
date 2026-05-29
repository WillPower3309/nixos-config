{ config, inputs, lib, ... }:

{
  flake.checks = lib.recursiveUpdate
    (builtins.mapAttrs (_: deployLib: deployLib.deployChecks config.flake.deploy) inputs.deploy-rs.lib)
    {
      x86_64-linux = builtins.mapAttrs
        (name: _: config.flake.homeConfigurations.${name}.activationPackage)
        config.flake.homeConfigurations;
    };
}
