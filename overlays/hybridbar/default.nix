self: super:

hybridbar = super.stdenv.mkDerivation rec {
  name = "hybridbar";

  src = super.fetchurl {
    url = "https://github.com/hcsubser/hybridbar/archive/main.tar.gz";
    sha256 = "10z0msxdi5n5qvgfb2p65p4nxpxq5z2x8g5g8lzs1ypgpcrbmn83";
  };

  nativeBuildInputs = with self; [
    gettext
    meson
    ninja
    pkg-config
    python3
    vala
    wrapGAppsHook
  ];
 
  buildInputs = with self; [
    gtk3
    json-glib
    libgee
    mesa
    gtk-layer-shell
  ];

  buildPhase = ''
    $out/indicators/build.sh --prefix=$out/usr
  '';
};
