final: prev:
{
#  stdenv = prev.ccacheStdenv;

#  ccacheWrapper = prev.ccacheWrapper.override {
#    extraConfig = ''
#      export CCACHE_DIR=/nix/var/ccache
#      export CCACHE_UMASK=007
#    '';
#  };
  stdenv = prev.stdenvAdapters.addAttrsToDerivation {
    NIX_CFLAGS_COMPILE = "-pipe -O2";
    #NIX_LDFLAGS = ;
    makeFlags = "-j5";
  } (prev.impureUseNativeOptimizations prev.stdenv);
}
