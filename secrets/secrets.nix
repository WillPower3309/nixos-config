let
  systemDesktop = builtins.readFile ../hosts/desktop/ssh_host_ed25519_key.pub;
  systemSurface = builtins.readFile ../hosts/surface/ssh_host_ed25519_key.pub;
  systemServer = builtins.readFile ../hosts/server/ssh_host_ed25519_key.pub;
  systems = [ systemDesktop systemSurface systemServer ];

  userWill = builtins.readFile ../home/id_ed25519.pub;
  editors = [ userWill ];

in
{
  # hashed user passwords (can be generated with `mkpasswd -m sha-512`)
  "hashedRootPassword.age".publicKeys = systems ++ editors;
  "hashedWillPassword.age".publicKeys = [ systemDesktop systemSurface ] ++ editors;
}
