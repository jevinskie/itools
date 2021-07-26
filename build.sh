#!/usr/bin/env zsh

set -o errexit
set -o nounset
set -o pipefail

set -o xtrace

repo_urls=(
	https://github.com/libimobiledevice/libplist
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
export ITOOLS_PREFIX=/opt/itools
mkdir -p ${ITOOLS_PREFIX}/include ${ITOOLS_PREFIX}/lib ${ITOOLS_PREFIX}/lib/pkgconfig ${ITOOLS_PREFIX}/lib/systemd/system ${ITOOLS_PREFIX}/lib/udev

# ln -fs $(greadlink -f wrappers/static-wrap.pl) wrappers/static-clang
# ln -fs $(greadlink -f wrappers/static-wrap.pl) wrappers/static-clang++

# export PATH=$PWD/wrappers:$PATH

# export CC=static-clang
# export CXX=static-clang++
export CFLAGS="-I${ITOOLS_PREFIX}/include"
export CXXFLAGS="${CFLAGS}"
# export LDFLAGS="-all-static -mmacosx-version-min=10.7"
export PKG_CONFIG_PATH="${ITOOLS_PREFIX}/lib/pkgconfig"

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
			git reset --hard
			git clean -fdx
			git pull
			NOCONFIGURE=1 ./autogen.sh
			configure_flags=''
			if [[ "${name}" = "libplist" ]]; then
				configure_flags='--enable-debug --without-cython'
			elif [[ "${name}" = "libimobiledevice" ]]; then
				configure_flags='--enable-debug-code --without-cython'
			elif [[ "${name}" == "usbmuxd" ]]; then
				configure_flags="--with-systemdsystemunitdir=${ITOOLS_PREFIX}/lib/systemd/system --with-udevrulesdir=${ITOOLS_PREFIX}/lib/udev"
			elif [[ "${name}" == "libirecovery" ]]; then
				configure_flags="--with-udevrulesdir=${ITOOLS_PREFIX}/lib/udev"
			fi
			./configure --prefix=${ITOOLS_PREFIX} ${=configure_flags}
			make -j4
			make install
		popd
	done
popd

