let
  user = builtins.readFile ../id_ed25519.pub;
in
{
  "keepass.age".publicKeys = [ user ];
}

