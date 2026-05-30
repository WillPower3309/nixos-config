let
  flakeConfig = builtins.getFlake (toString ./.);
  nixosConfigs = flakeConfig.nixosConfigurations;
  homeConfigs = flakeConfig.homeConfigurations;

  editors = [ builtins.readFile ./modules/features/ssh-client/id_ed25519.pub ];

  stripContext = builtins.unsafeDiscardStringContext;

  flakeStorePrefix = stripContext (toString flakeConfig.outPath) + "/";
  toLocalPath = p:
    let
      storePath = stripContext (toString p);
      relPath = builtins.substring (builtins.stringLength flakeStorePrefix) (builtins.stringLength storePath) storePath;
    in
    "./${relPath}";

  collectSecrets = config: extraFn:
    let
      ageSecrets = config.config.age.secrets or { };
    in
    map (name:
      let
        secretConfig = builtins.getAttr name ageSecrets;
        file = toLocalPath secretConfig.file;
      in
      { inherit file; } // extraFn name
    ) (builtins.attrNames ageSecrets);

  allSecrets = builtins.concatLists (
    map (name: collectSecrets (builtins.getAttr name nixosConfigs) (_: {
      key = builtins.readFile ./modules/hosts/${name}/ssh_host_ed25519_key.pub;
    })) (builtins.attrNames nixosConfigs)
    ++ map (name: collectSecrets (builtins.getAttr name homeConfigs) (_: { })) (builtins.attrNames homeConfigs)
  );

in builtins.mapAttrs (fileString: occurrences: {
  publicKeys = (builtins.filter (k: k != null)
    (map (occurrence: occurrence.key or null) occurrences)) ++ editors;
}) builtins.groupBy (item: item.file) allSecrets;

