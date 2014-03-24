export ITOOLS_PREFIX=$PWD/prefix
export PATH=$PWD/wrappers:$PATH
export LDFLAGS="-all-static -mmacosx-version-min=10.7"
export CXX=static-clang++
export CC=static-clang
export CFLAGS="-O0 -g"
export CXXFLAGS=$CFLAGS
export PKG_CONFIG_PATH=$ITOOLS_PREFIX/lib/pkgconfig:$(brew --prefix)/lib/pkgconfig:$(brew --prefix libxml2)/lib/pkgconfig:$PKG_CONFIG_PATH
