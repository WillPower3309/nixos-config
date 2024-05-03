{
  networking.hostName = "nixos-install";
  users.users.root.openssh.authorizedKeys.keys = [ (builtins.readFile ../home/id_ed25519.pub) ];
}
