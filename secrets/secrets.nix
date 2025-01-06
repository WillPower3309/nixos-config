let
  systemDesktop = builtins.readFile ../hosts/desktop/ssh_host_ed25519_key.pub;
  systemLaptop = builtins.readFile ../hosts/laptop/ssh_host_ed25519_key.pub;
  systemLighthouse = builtins.readFile ../hosts/lighthouse/ssh_host_ed25519_key.pub;
  systemSurface = builtins.readFile ../hosts/surface/ssh_host_ed25519_key.pub;
  systemServer = builtins.readFile ../hosts/server/ssh_host_ed25519_key.pub;

  headlessSystems = [ systemServer systemLighthouse ];
  guiSystems = [ systemDesktop systemLaptop systemSurface ];
  systems = guiSystems ++ headlessSystems;

  userWill = builtins.readFile ../home/id_ed25519.pub;
  editors = [ userWill ];

in
{
  # hashed user passwords (can be generated with `mkpasswd -m sha-512`)
  "hashedRootPassword.age".publicKeys = [ systemServer ] ++ guiSystems ++ editors;
  "hashedWillPassword.age".publicKeys = guiSystems ++ editors;

  "keepassKeyFile.age".publicKeys = guiSystems ++ editors;

  # syncthing certs and keys
  "desktopSyncthingKey.age".publicKeys = [ systemDesktop ] ++ editors;
  "desktopSyncthingCert.age".publicKeys = [ systemDesktop ] ++ editors;
  "laptopSyncthingKey.age".publicKeys = [ systemLaptop ] ++ editors;
  "laptopSyncthingCert.age".publicKeys = [ systemLaptop ] ++ editors;
  "surfaceSyncthingKey.age".publicKeys = [ systemSurface ] ++ editors;
  "surfaceSyncthingCert.age".publicKeys = [ systemSurface ] ++ editors;
  "serverSyncthingKey.age".publicKeys = [ systemServer ] ++ editors;
  "serverSyncthingCert.age".publicKeys = [ systemServer ] ++ editors;

  # nebula certs and keys
  "nebulaCaKey.age".publicKeys = editors;
  "nebulaCaCert.age".publicKeys = systems ++ editors;
  "lighthouseNebulaCert.age".publicKeys = [ systemLighthouse ] ++ editors;
  "lighthouseNebulaKey.age".publicKeys = [ systemLighthouse ] ++ editors;
  "serverNebulaCert.age".publicKeys = [ systemServer ] ++ editors;
  "serverNebulaKey.age".publicKeys = [ systemServer ] ++ editors;
  "desktopNebulaCert.age".publicKeys = [ systemDesktop ] ++ editors;
  "desktopNebulaKey.age".publicKeys = [ systemDesktop ] ++ editors;
  "laptopNebulaCert.age".publicKeys = [ systemLaptop ] ++ editors;
  "laptopNebulaKey.age".publicKeys = [ systemLaptop ] ++ editors;
  "surfaceNebulaCert.age".publicKeys = [ systemSurface ] ++ editors;
  "surfaceNebulaKey.age".publicKeys = [ systemSurface ] ++ editors;

  # wireguard keys
  "serverWireguardPrivateKey.age".publicKeys = [ systemServer ] ++ editors;
  "serverWireguardPeerPresharedKey.age".publicKeys = [ systemServer ] ++ editors;

  "radicaleHtpasswd.age".publicKeys = [ systemServer ] ++ editors;
  "tandoorSecretKey.age".publicKeys = [ systemServer ] ++ editors;
  "calibrePassword.age".publicKeys = [ systemServer ] ++ editors;
  "synapseSharedSecret.age".publicKeys = [ systemServer ] ++ editors;

  "acme.age".publicKeys = [ systemServer ] ++ editors;
}

