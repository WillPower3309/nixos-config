let
  desktopUser = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDQWOO2qMk2MP/YWfe2KKd8M1whdYYirh89/pAgMyEqW";
  users = [ desktopUser ];

  serverSystem = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDSiB38H1D4rTLcUsu617Z3n29L53OhdAk+QW/ibHQXW root@server";
  systems = [ serverSystem ];

in
{
  "desktopPrivateKey.age".publicKeys = [ serverSystem ];
}
