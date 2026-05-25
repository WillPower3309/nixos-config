{ inputs, ... }:

{
  flake.modules.nixos.root-user = { config, ... }: {
    imports = [
      inputs.agenix.nixosModules.age
    ];

    age.secrets.hashedRootPassword.file = ./hashedRootPassword.age;

    users = {
      users.root = {
        hashedPasswordFile = config.age.secrets.hashedRootPassword.path;
        openssh.authorizedKeys.keys = [ (builtins.readFile ../../ssh-client/id_ed25519.pub) ];
      };
      mutableUsers = false;
    };
  };
}
