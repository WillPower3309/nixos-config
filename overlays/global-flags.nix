final: prev:

{
  stdenv = prev.stdenv.override {
    waylandSupport = true;
    withWayland = true;

    x11Support = false;
    withX = false;

    xineramaSupport = false;
    xvSupport = false;
  };
}
