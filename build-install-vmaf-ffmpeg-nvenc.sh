#!/bin/bash

set -e

# component revisions to check out:
vpx_rev="HEAD"
x264_rev="HEAD"
x265_rev="tip"
fdk_aac_rev="HEAD"
ffmpeg_rev="HEAD"
# each will be set to the actual commit sha (git describe --abbrev)
PREFIX="$HOME/ffmpeg_build"
PATH=$HOME/bin:$PATH

common_config_options="--enable-static --disable-shared"

# this needs to be exported for opus.pc to be found. No idea why.
export CFLAGS="$CFLAGS -fPIC" CXXFLAGS="$CFLAGS"
export LDFLAGS="$LDFLAGS -L$PREFIX/lib"
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig"

mkdir -p ~/ffmpeg_sources ~/bin

cd ~/ffmpeg_sources && \
wget https://www.nasm.us/pub/nasm/releasebuilds/2.14.02/nasm-2.14.02.tar.bz2 && \
tar xjvf nasm-2.14.02.tar.bz2 && \
cd nasm-2.14.02 && \
./autogen.sh && \
PATH="$HOME/bin:$PATH" ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" && \
make && \
make install

cd ~/ffmpeg_sources && \
wget -O yasm-1.3.0.tar.gz https://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz && \
tar xzvf yasm-1.3.0.tar.gz && \
cd yasm-1.3.0 && \
./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" && \
make && \
make install

function build_lame {
    echo "
- - - -  lame"

    if check_lame; then
        true
    else
        local s="lame-3.100"
        local t=$s.tar.gz

        (cd ~/ffmpeg_sources
         test -r "$t" || curl -O -L http://downloads.sourceforge.net/project/lame/lame/3.100/$t
         test -d $s || tar xzf $t
         (cd $s
          ./configure --prefix="$PREFIX" --bindir="$HOME/bin" --enable-nasm $common_config_options
          make $MAKEOPTS
          make install)
         rm -rf $s)
    fi
}


function build_opus {
    echo "
- - - -  opus"

    if check_opus; then
        true
    else
        local s="opus-1.2.1"
        local t=$s.tar.gz

        (cd ~/ffmpeg_sources
         test -r "$t" || curl -O -L https://archive.mozilla.org/pub/opus/$t
         test -d $s || tar xzf $t
         (cd $s
          ./configure --prefix="$PREFIX" $common_config_options
          make $MAKEOPTS
          make install)
        rm -rf $s)
    fi
}

function build_libogg {
    echo "
- - - -  libogg"

    if check_libogg; then
        true
    else
        local s="libogg-1.3.3"
        local t=$s.tar.gz

        (cd ~/ffmpeg_sources
         test -r "$t" || curl -O -L http://downloads.xiph.org/releases/ogg/$t
         test -d $s || tar xzf $t
         (cd $s
          ./configure --prefix="$PREFIX" --bindir="$HOME/bin" $common_config_options
          make $MAKEOPTS
          make install)
        rm -rf $s)
    fi
}

function build_libvorbis {
    echo "
- - - -  libvorbis"

    if check_libvorbis; then
        true
    else
        local s="libvorbis-1.3.5"
        local t=$s.tar.gz

        (cd ~/ffmpeg_sources
         test -r "$t" || curl -O -L http://downloads.xiph.org/releases/vorbis/$t
         test -d $s || tar xzf $t
         (cd $s
          ./configure --prefix="$PREFIX" --bindir="$HOME/bin" $common_config_options
          make $MAKEOPTS
          make install)
        rm -rf $s)
    fi
}

build_lame
build_opus
build_libogg
build_libvorbis

cd ~/ffmpeg_sources && \
git -C x264 pull 2> /dev/null || git clone --depth 1 https://code.videolan.org/videolan/x264.git && \
cd x264 && \
PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" --enable-static --enable-pic && \
PATH="$HOME/bin:$PATH" make && \
make install

sudo apt-get install mercurial libnuma-dev && \
cd ~/ffmpeg_sources && \
if cd x265 2> /dev/null; then hg pull && hg update && cd ..; else hg clone https://bitbucket.org/multicoreware/x265; fi && \
cd x265/build/linux && \
PATH="$HOME/bin:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$HOME/ffmpeg_build" -DENABLE_SHARED=off ../../source && \
PATH="$HOME/bin:$PATH" make && \
make install

cd ~/ffmpeg_sources && \
git -C libvpx pull 2> /dev/null || git clone --depth 1 https://chromium.googlesource.com/webm/libvpx.git && \
cd libvpx && \
PATH="$HOME/bin:$PATH" ./configure --prefix="$HOME/ffmpeg_build" --disable-examples --disable-unit-tests --enable-vp9-highbitdepth --as=yasm && \
PATH="$HOME/bin:$PATH" make && \
make install

cd ~/ffmpeg_sources && \
git -C fdk-aac pull 2> /dev/null || git clone --depth 1 https://github.com/mstorsjo/fdk-aac && \
cd fdk-aac && \
autoreconf -fiv && \
./configure --prefix="$HOME/ffmpeg_build" --disable-shared && \
make && \
make install

cd ~/ffmpeg_sources && \
git -C aom pull 2> /dev/null || git clone --depth 1 https://aomedia.googlesource.com/aom && \
mkdir -p aom_build && \
cd aom_build && \
PATH="$HOME/bin:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$HOME/ffmpeg_build" -DENABLE_SHARED=off -DENABLE_NASM=on ../aom && \
PATH="$HOME/bin:$PATH" make && \
make install

cd ~/ffmpeg_sources && \
git clone --branch v1.3.15 https://github.com/Netflix/vmaf.git && \
cd vmaf/ptools && \
make -j $(nproc) && \
cd ../wrapper && \
make -j $(nproc) && \
cd .. && \
make install

cd ~/ffmpeg_sources && \
git clone https://github.com/sekrit-twc/zimg.git && \
cd zimg && \
./autogen.sh  && \
PATH="$HOME/bin:$PATH" ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" --disable-shared --enable-nasm && \
PATH="$HOME/bin:$PATH" make -j $(nproc) && \
make install &&

cd ~/ffmpeg_sources && \
git clone https://github.com/ffmpeg/ffmpeg.git

cd ~/ffmpeg_sources/ffmpeg && \
PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure \
  --prefix="$HOME/ffmpeg_build" \
  --pkg-config-flags="--static" \
  --extra-cflags="-I$HOME/ffmpeg_build/include" \
  --extra-ldflags="-L$HOME/ffmpeg_build/lib" \
  --extra-libs="-lpthread -lm" \
  --bindir="$HOME/bin" \
  --enable-gpl \
  --enable-nonfree \
  --enable-libaom \
  --enable-openssl \
  --enable-libfdk-aac \
  --enable-libfreetype \
  --enable-libmp3lame \
  --enable-libopus \
  --enable-libvorbis \
  --enable-libvpx \
  --enable-libx264 \
  --enable-libx265 \
  --enable-version3 \
  --enable-libvmaf && \
PATH="$HOME/bin:$PATH" make && \
make install && \
hash -r

cd ~/ffmpeg_sources && \
git clone git@github.com:FFmpeg/nv-codec-headers.git &&
cd nv-codec-headers && \
make && \
sudo make install PREFIX=/home/nick/ffmpeg_build

cd ~/ffmpeg_sources/ffmpeg && \
PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure \
  --prefix="$HOME/ffmpeg_build" \
  --pkg-config-flags="--static" \
  --bindir="$HOME/bin" \
  --extra-cflags="-I$HOME/ffmpeg_build/include" \
  --extra-ldflags="-L$HOME/ffmpeg_build/lib" \
  --enable-cuda-nvcc \
  --enable-cuvid \
  --enable-libnpp \
  --extra-cflags="-I/usr/local/cuda/include/" \
  --extra-ldflags=-L/usr/local/cuda/lib64/ \
  --enable-nvenc \
  --enable-libass \
  --disable-debug \
  --enable-libvorbis \
  --enable-libvpx \
  --enable-opencl \
  --enable-gpl \
  --cpu=native \
  --enable-libfdk-aac \
  --enable-libx264 \
  --enable-libx265 \
  --enable-openssl \
  --enable-librtmp \
  --extra-libs="-lpthread -lm -lz" \
  --enable-nonfree 
  --enable-version3 \
  --enable-libvmaf && \
PATH="$HOME/bin:$PATH" make -j$(nproc)
make -j$(nproc) install 
make -j$(nproc) distclean 
hash -r

echo

ffmpeg -version || exit 4

echo "
ffmpeg binary successfully built with these components:
  ffmpeg: $ffmpeg_rev
"

