#!/usr/bin/env zsh

repo_urls=(
	git://git.sukimashita.com/libplist.git
  git://git.sukimashita.com/libusbmuxd.git
	git://git.sukimashita.com/libimobiledevice.git
	git://git.sukimashita.com/libirecovery.git
	git://git.sukimashita.com/idevicerestore.git
	git://git.sukimashita.com/ideviceinstaller.git
)

# --build-bottle gives us -march=core2 instead of the default -march=native
# If we don't do that and build on, say, an AVX machine our binaries might not run on old procs
# brew install --build-bottle libxml2
# brew install pkg-config
# brew install --build-bottle libzip
# brew install libtool
# brew install --build-bottle xz
# brew install --build-bottle libusb

mkdir -p prefix/include prefix/lib
export ITOOLS_PREFIX=$PWD/prefix

ln -fs $(greadlink -f wrappers/static-wrap.pl) wrappers/static-clang
ln -fs $(greadlink -f wrappers/static-wrap.pl) wrappers/static-clang++

export PATH=$PWD/wrappers:$PATH

export CC=static-clang
export CXX=static-clang++
export CFLAGS="-O0 -g"
export CXXFLAGS=$CFLAGS
export LDFLAGS="-all-static -mmacosx-version-min=10.7"
export PKG_CONFIG_PATH=$ITOOLS_PREFIX/lib/pkgconfig:$(brew --prefix)/lib/pkgconfig:$(brew --prefix libxml2)/lib/pkgconfig:$PKG_CONFIG_PATH

mkdir -p src
pushd src
for url ($repo_urls); do
	name=$(basename -s .git $url)
	if [[ ! -d $name ]]; then
		git clone $url
	fi
	pushd $name
	NOCONFIGURE=1 ./autogen.sh
	./configure --prefix=$ITOOLS_PREFIX --disable-shared --enable-static
	make install
	popd
done
popd

pushd src/idevicecrashgrabber
make install
popd
