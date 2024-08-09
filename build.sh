#!/usr/bin/env zsh

set -o errexit
set -o nounset
set -o pipefail

set -o xtrace

repo_urls=(
	https://github.com/libimobiledevice/libplist
	https://github.com/libimobiledevice/libtatsu
	https://github.com/libimobiledevice/libimobiledevice-glue
	https://github.com/libimobiledevice/libusbmuxd
	https://github.com/libimobiledevice/libimobiledevice
	https://github.com/libimobiledevice/usbmuxd
	https://github.com/libimobiledevice/libirecovery
	https://github.com/libimobiledevice/idevicerestore
	https://github.com/libimobiledevice/ideviceinstaller
	https://github.com/libimobiledevice/libideviceactivation
	https://github.com/libimobiledevice/ifuse
)

# --build-bottle gives us -march=core2 instead of the default -march=native
# If we don't do that and build on, say, an AVX machine our binaries might not run on old procs
# brew install --build-bottle libxml2
# brew install pkg-config
# brew install --build-bottle libzip
# brew install libtool
# brew install --build-bottle xz
# brew install --build-bottle libusb

# export ITOOLS_PREFIX=${PWD}/prefix
export ITOOLS_PREFIX=~/base/limd
rm -rf ${ITOOLS_PREFIX}
mkdir -p ${ITOOLS_PREFIX}/include ${ITOOLS_PREFIX}/lib ${ITOOLS_PREFIX}/lib/pkgconfig

# ln -fs $(greadlink -f wrappers/static-wrap.pl) wrappers/static-clang
# ln -fs $(greadlink -f wrappers/static-wrap.pl) wrappers/static-clang++

# export PATH=$PWD/wrappers:$PATH

BROOT=$(brew --prefix)
BOPT="${BROOT}/opt"

brew update
brew install libtool autoconf automake pkgconfig libxml2 libzip xz zlib libusb gnutls libtasn1 curl mbedtls readline

# export CC=static-clang
# export CXX=static-clang++
export CFLAGS="-O0 -g -I${ITOOLS_PREFIX}/include"
export CXXFLAGS="${CFLAGS}"
export LDFLAGS="-L${ITOOLS_PREFIX}/lib"
# export LDFLAGS="-all-static -mmacosx-version-min=10.7"
export PKG_CONFIG_PATH="${ITOOLS_PREFIX}/lib/pkgconfig:${BOPT}/libusb/lib/pkgconfig:${BOPT}/libxml2/lib/pkgconfig:${BOPT}/libzip/lib/pkgconfig:${BOPT}/xz/lib/pkgconfig:${BOPT}/zlib/lib/pkgconfig:${BOPT}/curl/lib/pkgconfig:${BOPT}/mbedtls/lib/pkgconfig:${BOPT}/openssl@3/lib/pkgconfig:${BOPT}/libtasn1/lib/pkgconfig:${BOPT}/gnutls/lib/pkgconfig:${BOPT}/readline/lib/pkgconfig:${BROOT}/lib/pkgconfig"

echo CC: ${CC:-NOT_SET}
echo CXX: ${CXX:-NOT_SET}
echo CFLAGS: ${CFLAGS:-NOT_SET}
echo CXXFLAGS: ${CXXFLAGS:-NOT_SET}
echo LDFLAGS: ${LDFLAGS:-NOT_SET}
echo PKG_CONFIG_PATH: ${PKG_CONFIG_PATH:-NOT_SET}

NPROC=$(nproc)

mkdir -p src
pushd src
	for url (${repo_urls}); do
		name=$(basename -s .git ${url})
		if [[ ! -d ${name} ]]; then
			git clone ${url}
		fi
		pushd ${name}
			git reset --hard
			git clean -fdx
			git pull
			NOCONFIGURE=1 ./autogen.sh
			configure_flags=""
			if [[ "${name}" = "libplist" ]]; then
				configure_flags="${configure_flags} --without-cython --enable-debug"
			elif [[ "${name}" = "libimobiledevice" ]]; then
				configure_flags="${configure_flags} --without-cython --enable-debug"
			fi
			./configure --prefix=${ITOOLS_PREFIX} ${=configure_flags}
			make -j $(NPROC)
			make install
		popd
	done
popd

