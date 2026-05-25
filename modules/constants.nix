{
  flake.constants = { config, lib, ... }: {
    options.constants = lib.mkOption {
      type = lib.types.attrsOf lib.types.unspecified;
      default = { };
    };

    config.constants = {
      domain = "willmckinnon.com";
      loopbackAddr = "127.0.0.1";
      persistentDir = if config.networking.hostName or "" == "server"
        then "/persist"
        else "/nix/persist";
    };
  };
}
