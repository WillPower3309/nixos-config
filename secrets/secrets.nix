let
  systemDesktop = builtins.readFile ../hosts/desktop/ssh_host_ed25519_key.pub;
  systemLighthouse = builtins.readFile ../hosts/lighthouse/ssh_host_ed25519_key.pub;
  systemSurface = builtins.readFile ../hosts/surface/ssh_host_ed25519_key.pub;
  systemServer = builtins.readFile ../hosts/server/ssh_host_ed25519_key.pub;

  guiSystems = [ systemDesktop systemSurface ];
  headlessSystems = [ systemServer systemLighthouse ];
  systems = guiSystems ++ headlessSystems;

  userWill = builtins.readFile ../home/id_ed25519.pub;
  editors = [ userWill ];

in
{
  # hashed user passwords (can be generated with `mkpasswd -m sha-512`)
  "hashedRootPassword.age".publicKeys = [ systemServer ] ++ guiSystems ++ editors;
  "hashedWillPassword.age".publicKeys = guiSystems ++ editors;

  "keepassKeyFile.age".publicKeys = guiSystems ++ editors;

  "desktopSyncthingKey.age".publicKeys = [ systemDesktop ] ++ editors;
  "desktopSyncthingCert.age".publicKeys = [ systemDesktop ] ++ editors;
  "surfaceSyncthingKey.age".publicKeys = [ systemSurface ] ++ editors;
  "surfaceSyncthingCert.age".publicKeys = [ systemSurface ] ++ editors;
  "serverSyncthingKey.age".publicKeys = [ systemServer ] ++ editors;
  "serverSyncthingCert.age".publicKeys = [ systemServer ] ++ editors;

  "nebulaCaCert.age".publicKeys = [ systemLighthouse ] ++ editors;
  "nebulaCaKey.age".publicKeys = [ systemLighthouse ] ++ editors;
  "nebulaLighthouseCert.age".publicKeys = [ systemLighthouse ] ++ editors;
  "nebulaLighthouseKey.age".publicKeys = [ systemLighthouse ] ++ editors;
}
