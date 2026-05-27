let
  flakeConfig = builtins.getFlake (toString ./.);
  nixosConfigs = flakeConfig.nixosConfigurations;
  homeConfigs = flakeConfig.homeConfigurations;

  userWill = builtins.readFile ./modules/features/ssh-client/id_ed25519.pub;
  editors = [ userWill ];

  stripContext = builtins.unsafeDiscardStringContext;

  secretsFromHost = hostName:
    let
      hostConfig = builtins.getAttr hostName nixosConfigs;
      hasAgeSecrets = builtins.hasAttr "age" hostConfig.config
        && builtins.hasAttr "secrets" hostConfig.config.age;
    in
    if hasAgeSecrets then
      builtins.map (secretName:
        let
          secretConfig = builtins.getAttr secretName hostConfig.config.age.secrets;
          file = "./secrets/${builtins.baseNameOf (stripContext (toString secretConfig.file))}";
        in {
          inherit file;
          key = builtins.readFile ./modules/hosts/${hostName}/ssh_host_ed25519_key.pub;
        }
      ) (builtins.attrNames hostConfig.config.age.secrets)
    else [ ];

  secretsFromHome = homeName:
    let
      homeConfig = builtins.getAttr homeName homeConfigs;
      hasAgeSecrets = builtins.hasAttr "age" homeConfig.config
        && builtins.hasAttr "secrets" homeConfig.config.age;
    in
    if hasAgeSecrets then
      builtins.map (secretName:
        let
          secretConfig = builtins.getAttr secretName homeConfig.config.age.secrets;
          file = "./secrets/${builtins.baseNameOf (stripContext (toString secretConfig.file))}";
        in {
          inherit file;
        }
      ) (builtins.attrNames homeConfig.config.age.secrets)
    else [ ];

  allSecrets = builtins.concatLists [
    (builtins.concatLists (builtins.map secretsFromHost (builtins.attrNames nixosConfigs)))
    (builtins.concatLists (builtins.map secretsFromHome (builtins.attrNames homeConfigs)))
  ];

  groupedSecrets = builtins.groupBy (item: item.file) allSecrets;

in builtins.mapAttrs (fileString: occurrences: {
  publicKeys = (builtins.filter (k: k != null)
    (map (occurrence: occurrence.key or null) occurrences)) ++ editors;
}) groupedSecrets

