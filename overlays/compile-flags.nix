final: prev:
{
  stdenv = prev.stdenvAdapters.addAttrsToDerivation {
    #NIX_CFLAGS_COMPILE = "-pipe -O2";
    #NIX_LDFLAGS = "";
    #makeFlags = "-j5";
  } (prev.impureUseNativeOptimizations prev.stdenv);
}
