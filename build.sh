#!/usr/bin/env zsh

set -o errexit
set -o nounset
set -o pipefail

set -o xtrace

repo_urls=(
	https://github.com/libimobiledevice/libplist
	https://github.com/libimobiledevice/libusbmuxd
	https://github.com/libimobiledevice/libimobiledevice
	https://github.com/libimobiledevice/libirecovery
	https://github.com/libimobiledevice/idevicerestore
	https://github.com/libimobiledevice/ideviceinstaller
	https://github.com/libimobiledevice/libideviceactivation
)

# --build-bottle gives us -march=core2 instead of the default -march=native
# If we don't do that and build on, say, an AVX machine our binaries might not run on old procs
# brew install --build-bottle libxml2
# brew install pkg-config
# brew install --build-bottle libzip
# brew install libtool
# brew install --build-bottle xz
# brew install --build-bottle libusb

export ITOOLS_PREFIX=${PWD}/prefix
mkdir -p ${ITOOLS_PREFIX}/include ${ITOOLS_PREFIX}/lib ${ITOOLS_PREFIX}/lib/pkgconfig

# ln -fs $(greadlink -f wrappers/static-wrap.pl) wrappers/static-clang
# ln -fs $(greadlink -f wrappers/static-wrap.pl) wrappers/static-clang++

# export PATH=$PWD/wrappers:$PATH

# export CC=static-clang
# export CXX=static-clang++
export CFLAGS="-O0 -g"
export CXXFLAGS="${CFLAGS}"
# export LDFLAGS="-all-static -mmacosx-version-min=10.7"
export PKG_CONFIG_PATH="${ITOOLS_PREFIX}/lib/pkgconfig:$(brew --prefix libusb)/lib/pkgconfig:$(brew --prefix libxml2)/lib/pkgconfig:$(brew --prefix libzip)/lib/pkgconfig:$(brew --prefix zlib)/lib/pkgconfig:$(brew --prefix curl)/lib/pkgconfig:$(brew --prefix openssl)/lib/pkgconfig:$(brew --prefix libtasn1)/lib/pkgconfig:$(brew --prefix gnutls)/lib/pkgconfig"

echo CC: ${CC:-NOT_SET}
echo CXX: ${CXX:-NOT_SET}
echo CFLAGS: ${CFLAGS:-NOT_SET}
echo CXXFLAGS: ${CXXFLAGS:-NOT_SET}
echo LDFLAGS: ${LDFLAGS:-NOT_SET}
echo PKG_CONFIG_PATH: ${PKG_CONFIG_PATH:-NOT_SET}

mkdir -p src
pushd src
	for url (${repo_urls}); do
		name=$(basename -s .git ${url})
		if [[ ! -d ${name} ]]; then
			git clone ${url}
		fi
		pushd ${name}
			NOCONFIGURE=1 ./autogen.sh
			configure_flags=''
			if [[ "${name}" = "libplist" ]]; then
				configure_flags='--enable-debug --without-cython'
			elif [[ "${name}" = "libimobiledevice" ]]; then
				configure_flags='--enable-debug-code --without-cython'
			fi
			./configure --prefix=${ITOOLS_PREFIX} ${=configure_flags}
			make -j8
			make install
		popd
	done
popd

