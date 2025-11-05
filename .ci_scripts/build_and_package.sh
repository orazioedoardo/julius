#!/usr/bin/env bash

# docker run --rm --device /dev/fuse --cap-add SYS_ADMIN -i -v ${PWD}:/julius ubuntu:jammy < .ci_scripts/build_and_package.sh

set -xe

system_arch="$(uname -m)"

sw_version="1.8.0"

# These are rolling versions, it shouldn't be assumed that a subsequent build will use the same tool and runtime code
appimagetool_version="continuous"
appimagetool_filename="appimagetool-$system_arch.AppImage"
appimagetool_baseurl="https://github.com/AppImage/appimagetool/releases/download/$appimagetool_version"

runtime_version="continuous"
runtime_filename="runtime-$system_arch"
runtime_baseurl="https://github.com/AppImage/type2-runtime/releases/download/$runtime_version"

# Shared libraries as of Ubuntu 22.04
required_libs=(
	libSDL2_mixer-2.0.so.0
	libSDL2-2.0.so.0

	libbsd.so.0
	libdecor-0.so.0
	libFLAC.so.8
	libfluidsynth.so.3
	libinstpatch-1.0.so.2
	libmd.so.0
	libmodplug.so.1
	libmpg123.so.0
	libogg.so.0
	libopus.so.0
	libsndfile.so.1
	libvorbis.so.0
	libvorbisenc.so.2
	libvorbisfile.so.3
	libXss.so.1
)

apt-get update
apt-get install --yes build-essential \
	cmake \
	curl \
	desktop-file-utils \
	file \
	fuse3 \
	libgl1-mesa-dev \
	libsdl2-dev \
	libsdl2-mixer-dev \
	software-properties-common \
	unzip \

pushd /julius
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DSYSTEM_LIBS=OFF -DENABLE_TESTS=OFF -DCMAKE_INSTALL_PREFIX=/usr
cmake --build build -j "$(nproc)"
.ci_scripts/get_support_files.sh

mkdir -p julius.AppDir/usr/{bin,lib,share/{applications,metainfo,icons}}

cp -a assets julius.AppDir/usr/share/
cp -a support/languages/* julius.AppDir/usr/share/assets/
cp -a support/editor/* julius.AppDir/usr/share/assets/
cp -a support/mp3 julius.AppDir/usr/share/assets/
cp -a build/julius julius.AppDir/usr/bin/

cp -a res/AppRun julius.AppDir/
cp -a res/julius_256.png julius.AppDir/usr/share/icons/com.github.bvschaik.julius.png
cp -a res/julius.desktop julius.AppDir/usr/share/applications/com.github.bvschaik.julius.desktop
cp -a res/julius.metainfo.xml julius.AppDir/usr/share/metainfo/com.github.bvschaik.julius.appdata.xml

pushd julius.AppDir
ln -sf usr/share/applications/com.github.bvschaik.julius.desktop com.github.bvschaik.julius.desktop
ln -sf usr/share/icons/com.github.bvschaik.julius.png com.github.bvschaik.julius.png
popd

# For some reason this library is not in /lib/$system_arch-linux-gnu/$lib
cp -a -L /usr/lib/libopusfile.so.0 julius.AppDir/usr/lib/

for lib in "${required_libs[@]}"; do
	cp -a -L "/lib/$system_arch-linux-gnu/$lib" julius.AppDir/usr/lib/
done

if [ ! -f "$appimagetool_filename" ]; then
	curl -sSf -L -O "$appimagetool_baseurl/$appimagetool_filename"
	chmod +x "$appimagetool_filename"
fi

if [ ! -f "$runtime_filename" ]; then
	curl -sSf -L -O "$runtime_baseurl/$runtime_filename"
	chmod +x "$runtime_filename"
fi

pushd julius.AppDir
rm -r usr/share/assets/__redist
find . -type f -name .DS_Store -delete
find . -type f ! -path ./AppRun ! -path ./usr/bin/julius -exec chmod 0644 {} +
find . -type d -exec chmod 0755 {} +
popd

./"$appimagetool_filename" --no-appstream --runtime-file "runtime-$system_arch" julius.AppDir "julius-$sw_version-linux-$system_arch.AppImage"

rm -r julius.AppDir
