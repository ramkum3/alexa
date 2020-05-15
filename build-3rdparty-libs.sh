#!/bin/sh

#======================================================================================================================================
#setenv.sh is used to compile all the netflix NRDP-4.3.x 3rdparty libraries
#Libraries which is compiling in this file: Freetype, ICU, Zlib, Openssl, Harfbuzz, JPEG, MNG, PNG, WEBP, C-ares, Curl, OGG, Tremor, Expat
#Input argument for compilation is absolute-compiler-path, LOCAL_PLATFORM_PREFIX[ex:-mipsel-linux-uclibc] and the build-mode(debug or release)
#Needed header and libraries files for Netflix NRDP-4.3.x compilation will be copied to Netflix folder
#======================================================================================================================================

#=TO Do================================================================================================================================
#1. Need to change the script to take the CC Flag, CPP Flag and other compiler options from platform.mk.
#2. Need to use the Openssl from our stack(which is used in webkit browser),instead of using other.
#3. Freetype configure param for --with-zlib=no --with-png=no has to be reviewed.
#4. Need to change the process_build function have to pass include directory and library path as input parameter.
#   Since we are copying every time, we can do it in process_build itself.
#======================================================================================================================================

echo $0
CUR_DIR=$(pwd)
cd ${0%/*}

MY_DIR=$(pwd)
echo $MY_DIR

COMPILER_ROOT=$1
LOCAL_PLATFORM_PREFIX=$2

mkdir -p Alexa Alexa/lib Alexa/include

LOCAL_LIB_PATH="$MY_DIR/Alexa/lib"
LOCAL_INC_PATH="$MY_DIR/Alexa/include"
LOCAL_THIRDPARTY_PATH="$MY_DIR/Alexa"

LOCAL_PLATFORM_AS=$COMPILER_ROOT/bin/$LOCAL_PLATFORM_PREFIX-as
LOCAL_PLATFORM_CC=$COMPILER_ROOT/bin/$LOCAL_PLATFORM_PREFIX-gcc
LOCAL_PLATFORM_CPP=$COMPILER_ROOT/bin/$LOCAL_PLATFORM_PREFIX-g++
LOCAL_PLATFORM_AR=$COMPILER_ROOT/bin/$LOCAL_PLATFORM_PREFIX-ar
LOCAL_PLATFORM_LD=$COMPILER_ROOT/bin/$LOCAL_PLATFORM_PREFIX-ld
LOCAL_PLATFORM_RANLIB=$COMPILER_ROOT/bin/$LOCAL_PLATFORM_PREFIX-ranlib
LOCAL_PLATFORM_STRIP=$COMPILER_ROOT/bin/$LOCAL_PLATFORM_PREFIX-strip
LOCAL_PLATFORM_LD_FLAGS="-shared-libgcc -Wl,-rpath-link=$COMPILER_ROOT/$LOCAL_PLATFORM_PREFIX/lib:$LOCAL_LIB_PATH -L$LOCAL_LIB_PATH"
echo $LOCAL_PLATFORM_AS $LOCAL_PLATFORM_CC $LOCAL_PLATFORM_CPP

if [ ! $COMPILER_ROOT ]
then
   echo "Invalid choice [${1}]... Usage ./build-3rdparty-libs.sh absolute_compiler_path LOCAL_PLATFORM_PREFIX[ex:-mipsel-linux-uclibc] debug(or) ./setenv.sh absolute_compiler_path release"
   exit 1
fi

#Please use the LOCAL_PLATFORM_CPP_FLAGS and LOCAL_PLATFORM_CC_FLAGS as per defined in your platform.mk
if [ $3 = "release" ]
then
	LOCAL_PLATFORM_CPP_FLAGS="-O0 -fno-strict-aliasing -Wall -fno-builtin -DNeedFunctioPrototypes=1 -Wshadow -Wpointer-arith -fno-optimize-sibling-calls -ffunction-sections -fdata-sections -fexceptions -I$LOCAL_INC_PATH"
	LOCAL_PLATFORM_CC_FLAGS="-O0 -fno-builtin -Wmissing-prototypes -Wshadow -Wpointer-arith -Wstrict-prototypes -fno-optimize-sibling-calls -ffunction-sections -fdata-sections -fexceptions"
elif [ "$3" = "debug" ]
then
	LOCAL_PLATFORM_CPP_FLAGS="-O0 -g -fno-strict-aliasing -Wall -fno-builtin -DNeedFunctioPrototypes=1 -Wshadow -Wpointer-arith -fno-optimize-sibling-calls -ffunction-sections -fdata-sections -fexceptions -I$LOCAL_INC_PATH"
	LOCAL_PLATFORM_CC_FLAGS="-O0 -g -fno-builtin -Wmissing-prototypes -Wshadow -Wpointer-arith -Wstrict-prototypes -fno-optimize-sibling-calls -ffunction-sections -fdata-sections -fexceptions"
else
    echo "Invalid choice [${3}]... Usage ./build-3rdparty-libs.sh absolute_compiler_path LOCAL_PLATFORM_PREFIX[ex:-mipsel-linux-uclibc] debug(or) ./setenv.sh absolute_compiler_path LOCAL_PLATFORM_PREFIX[ex:-mipsel-linux-uclibc] release"
	exit 1
fi

LOCAL_PLATFORM_AS=$COMPILER_ROOT/bin/$LOCAL_PLATFORM_PREFIX-as
LOCAL_PLATFORM_CC=$COMPILER_ROOT/bin/$LOCAL_PLATFORM_PREFIX-gcc
LOCAL_PLATFORM_CPP=$COMPILER_ROOT/bin/$LOCAL_PLATFORM_PREFIX-g++
LOCAL_PLATFORM_AR=$COMPILER_ROOT/bin/$LOCAL_PLATFORM_PREFIX-ar
LOCAL_PLATFORM_LD=$COMPILER_ROOT/bin/$LOCAL_PLATFORM_PREFIX-ld
LOCAL_PLATFORM_RANLIB=$COMPILER_ROOT/bin/$LOCAL_PLATFORM_PREFIX-ranlib
LOCAL_PLATFORM_STRIP=$COMPILER_ROOT/bin/$LOCAL_PLATFORM_PREFIX-strip

LOCAL_PLATFORM_LD_FLAGS="-shared-libgcc -Wl,-rpath-link=$COMPILER_ROOT/$LOCAL_PLATFORM_PREFIX/lib:$LOCAL_LIB_PATH -L$LOCAL_LIB_PATH"

process_config ()
{
	CC=$LOCAL_PLATFORM_CC CXX=$LOCAL_PLATFORM_CPP AR=$LOCAL_PLATFORM_AR LD=$LOCAL_PLATFORM_LD RANLIB=$LOCAL_PLATFORM_RANLIB CFLAGS=$LOCAL_PLATFORM_CC_FLAGS CPPFLAGS=$LOCAL_PLATFORM_CPP_FLAGS CXXFLAGS= LDFLAGS=$LOCAL_PLATFORM_LD_FLAGS $CONFIG_PATH/./$CONFIG_CMD $CONFIG_PARAM
    echo $CC "cc"
}

process_build()
{
	make
	make install
}

build_zlib()
{
#Zlib
mkdir Zlib
tar -xvf zlib-1.2.8.tar.gz --directory Zlib/
cd Zlib/zlib-1.2.8/
CONFIG_CMD=configure
CONFIG_PATH=./
CONFIG_PARAM=$"--enable-shared --prefix=$(pwd) --eprefix=$(pwd)"
process_config
process_build
cp -P lib/lib*.so* $LOCAL_LIB_PATH
cp include/zlib.h include/zconf.h $LOCAL_INC_PATH
cd ../../
}

build_openssl()
{
#Openssl
mkdir Openssl
tar -xvf openssl-1.1.1e.tar.gz --directory Openssl/
cd Openssl/openssl-1.1.1e/
mkdir output
CONFIG_CMD=Configure
CONFIG_PATH=./
CONFIG_PARAM=$"linux-generic32 shared --with-zlib-lib=LOCAL_LIB_PATH --with-zlib-include=LOCAL_INC_PATH --prefix=$(pwd)/output"
process_config
process_build
cp -R output/include/. $LOCAL_INC_PATH/
chmod -R 777 output/lib/lib*.so*
cp -P output/lib/lib*.so* $LOCAL_LIB_PATH
cd ../../
}

build_cares()
{
#C-ares
mkdir C-ares
tar -xvf c-ares-1.16.0.tar.gz --directory C-ares/
cd C-ares/c-ares-1.16.0/
CONFIG_CMD=configure
CONFIG_PATH=./
CONFIG_PARAM=$"--build=i686-linux-gnu --host=$LOCAL_PLATFORM_PREFIX --disable-debug --enable-optimize --with-random=/dev/urandom --libdir=$(pwd)/lib --includedir=$(pwd)/inc --prefix=$(pwd) --exec-prefix=$(pwd)"
process_config
process_build
cp -P lib/lib*.so* $LOCAL_LIB_PATH
cp -R inc/. $LOCAL_INC_PATH
cd ../../
}

build_curl()
{
#Curl
mkdir Curl
tar -xvf curl-7.52.1.tar.bz2 --directory Curl/
cd Curl/curl-7.52.1/
mkdir libs inc
CONFIG_CMD=configure
CONFIG_PATH=./
CONFIG_PARAM=$"--host=$LOCAL_PLATFORM_PREFIX --enable-optimize --enable-shared --libdir=$(pwd)/libs --includedir=$(pwd)/inc --prefix=$(pwd) --exec-prefix=$(pwd) --disable-ftp --disable-file --disable-ldap --disable-ldaps --disable-rtsp --disable-dict --disable-telnet --disable-tftp --disable-gopher --disable-pop3 --disable-imap --disable-smtp --without-libidn2 --enable-ipv6 --with-ssl=$LOCAL_THIRDPARTY_PATH --enable-ares=$LOCAL_THIRDPARTY_PATH --enable-cookies --with-ca-bundle=/NDS/Alexa/etc/ssl/certs/ca-certificates.crt --with-ca-path=/NDS/Alexa/etc/ssl/certs/ --with-zlib=$LOCAL_THIRDPARTY_PATH --with-nghttp2=$LOCAL_THIRDPARTY_PATH PKG_CONFIG_PATH=$MY_DIR/nghttp2/nghttp2-1.37.0/libs/pkgconfig"
process_config
process_build
cp -P lib/.libs/lib*.so* $LOCAL_LIB_PATH
cp -R include/curl $LOCAL_INC_PATH/
cd ../../
}

build_nghttp2()
{
#nghttp2
mkdir nghttp2
tar -xvf nghttp2-1.40.0.tar.xz --directory nghttp2/
cd nghttp2/nghttp2-1.40.0/
CONFIG_CMD=configure
CONFIG_PATH=./
CONFIG_PARAM=$"--host=$LOCAL_PLATFORM_PREFIX --enable-shared --libdir=$(pwd)/libs --includedir=$(pwd)/include --prefix=$(pwd) --exec-prefix=$(pwd)"
process_config
process_build
cp -P lib/.libs/lib*.so* $LOCAL_LIB_PATH
cp -R include/. $LOCAL_INC_PATH
cd ../../
}

build_sqlite3()
{
#sqlite3
mkdir sqlite3
tar -xvf sqlite-autoconf-3220000.tar.gz --directory sqlite3/
cd sqlite3/sqlite-autoconf-3220000/
CONFIG_CMD=configure
CONFIG_PATH=./
CONFIG_PARAM=$"--host=$LOCAL_PLATFORM_PREFIX --enable-shared --libdir=$(pwd)/libs --includedir=$(pwd)/include --prefix=$(pwd) --exec-prefix=$(pwd)"
process_config
process_build
cp -P .libs/lib*.so* $LOCAL_LIB_PATH
cp -R include/. $LOCAL_INC_PATH
cd ../../
}

build_alsa()
{
#alsa
mkdir alsa
tar -xvf alsa-lib-1.1.6.tar.bz2 --directory alsa/
cd alsa/alsa-lib-1.1.6/
rm -rf inc
mkdir inc
CONFIG_CMD=configure
CONFIG_PATH=./
CONFIG_PARAM=$"--host=$LOCAL_PLATFORM_PREFIX --prefix=$(pwd) --includedir=$(pwd)/inc --exec-prefix=$(pwd)"
process_config
process_build
cp -P lib/lib*.so* $LOCAL_LIB_PATH
cp -R inc/. $LOCAL_INC_PATH
cd ../../
}

build_portaudio()
{
#portaudio
mkdir portaudio
tar -xvf pa_stable_v190600_20161030.tgz --directory portaudio/
cd portaudio/portaudio/
rm -rf inc
mkdir inc
cp -rf $MY_DIR/alsa/alsa-lib-1.1.6/inc/alsa $(pwd)/include
CONFIG_CMD=configure
CONFIG_PATH=./
CONFIG_PARAM=$"--host=$LOCAL_PLATFORM_PREFIX --prefix=$(pwd) --exec-prefix=$(pwd) --includedir=$(pwd)/inc"
process_config
process_build
cp -P lib/.libs/lib*.so* $LOCAL_LIB_PATH
cp -P lib/.libs/libportaudio.a $LOCAL_LIB_PATH
cp -R include/. $LOCAL_INC_PATH
cd ../../
}

build_ffi()
{
#ffi
mkdir ffi
tar -xvf libffi-3.2.1.tar.gz --directory ffi/
cd ffi/libffi-3.2.1/
CONFIG_CMD=configure
CONFIG_PATH=./
CONFIG_PARAM=$"--host=$LOCAL_PLATFORM_PREFIX --enable-shared --disable-static --libdir=$(pwd)/libs --includedir=$(pwd)/include --prefix=$(pwd) --exec-prefix=$(pwd)"
process_config
process_build
cp -P lib64/lib*.so* $LOCAL_LIB_PATH
cp -R libs/libffi-3.2.1/include/. $LOCAL_INC_PATH
cd ../../
}

build_glib()
{
#glib
mkdir glib
tar -xvf glib-2.54.3.tar.xz --directory glib/
cd glib/glib-2.54.3/
cp ../../config.cache .
CONFIG_CMD=configure
CONFIG_PATH=./
CONFIG_PARAM=$"--host=$LOCAL_PLATFORM_PREFIX --enable-shared --libdir=$(pwd)/libs --includedir=$(pwd)/include --prefix=$(pwd) --cache-file=config.cache PKG_CONFIG_PATH=$MY_DIR/ffi/libffi-3.2.1/libs/pkgconfig --with-pcre=internal --disable-libmount --disable-gtk-doc --exec-prefix=$(pwd)"
process_config
process_build
cp -P libs/lib*.so* $LOCAL_LIB_PATH
cp -R include/. $LOCAL_INC_PATH
cp -R libs/glib-2.0/include/. $LOCAL_INC_PATH
cd ../../
}

build_gstreamer()
{
#gstreamer
mkdir gstreamer
tar -xvf gstreamer-1.12.4.tar.xz --directory gstreamer/
cd gstreamer/gstreamer-1.12.4/
export PATH=flex$PATH
CONFIG_CMD=configure
CONFIG_PATH=./
CONFIG_PARAM=$"--host=$LOCAL_PLATFORM_PREFIX --enable-shared --libdir=$(pwd)/libs --includedir=$(pwd)/include --prefix=$(pwd) --exec-prefix=$(pwd) --disable-gtk-doc PKG_CONFIG_PATH=$MY_DIR/glib/glib-2.54.3/libs/pkgconfig"
process_config
process_build
cp -P libs/lib*.so* $LOCAL_LIB_PATH
cd libs/
cp --parents -P gstreamer-1.0/lib*.so* $LOCAL_LIB_PATH
cd ../
cp --parents libexec/gstreamer-1.0/gst-plugin-scanner $LOCAL_LIB_PATH
cp -R include/. $LOCAL_INC_PATH
cd ../../
}

build_gstplugin()
{
#gstplugin
mkdir gstplugin
tar -xvf gst-plugins-base-1.12.4.tar.xz --directory gstplugin/
cd gstplugin/gst-plugins-base-1.12.4/
export GLIB_CFLAGS=-I$MY_DIR/Alexa/include/glib-2.0/
export GLIB_LIBS="-L$MY_DIR/Alexa/lib"
export GIO_CFLAGS=-I$MY_DIR/Alexa/include/glib-2.0/
export GIO_LIBS="-L$MY_DIR/Alexa/lib"
cp $MY_DIR/glib/glib-2.54.3/libs/pkgconfig/* $MY_DIR/gstreamer/gstreamer-1.12.4/libs/pkgconfig/
CONFIG_CMD=configure
CONFIG_PATH=./
CONFIG_PARAM=$"--host=$LOCAL_PLATFORM_PREFIX --enable-shared --libdir=$(pwd)/libs --includedir=$(pwd)/include --prefix=$(pwd) --exec-prefix=$(pwd) --disable-xvideo --disable-x --disable-libvisual --disable-opus --disable-xshm --disable-ogg --disable-pango --disable-theora --disable-vorbis --disable-audiotestsrc --disable-gtk-doc --disable-examples --disable-alsa PKG_CONFIG_PATH=$MY_DIR/gstreamer/gstreamer-1.12.4/libs/pkgconfig "
process_config
process_build
cp -P libs/lib*.so* $LOCAL_LIB_PATH
cd libs/
cp --parents -P gstreamer-1.0/lib*.so* $LOCAL_LIB_PATH
cd ../
cp -R include/. $LOCAL_INC_PATH
cd ../../
}

build_gstpluginsgood()
{
#gstpluginsgood
mkdir gstpluginsgood
tar -xvf gst-plugins-good-1.12.4.tar.xz --directory gstpluginsgood/
cd gstpluginsgood/gst-plugins-good-1.12.4/
mkdir $MY_DIR/gstreamer/pkgconfig
cp $MY_DIR/gstreamer/gstreamer-1.12.4/libs/pkgconfig/* $MY_DIR/gstreamer/pkgconfig/
cp $MY_DIR/gstplugin/gst-plugins-base-1.12.4/libs/pkgconfig/* $MY_DIR/gstreamer/pkgconfig/
CONFIG_CMD=configure
CONFIG_PATH=./
CONFIG_PARAM=$"--host=$LOCAL_PLATFORM_PREFIX --enable-shared --libdir=$(pwd)/libs --includedir=$(pwd)/include --prefix=$(pwd) --exec-prefix=$(pwd)  --disable-gtk-doc --disable-examples --disable-videobox --disable-videocrop --disable-videofilter --disable-videomixer --disable-x --disable-cairo --disable-aalib --disable-aalibtest --disable-flac --disable-jack --disable-libcaca --disable-libpng --disable-libdv --disable-pulse --disable-dv1394 --disable-gdk_pixbuf --disable-qt --disable-shout2 --disable-soup --disable-speex --disable-vpx --disable-wavpack PKG_CONFIG_PATH=$MY_DIR/gstreamer/pkgconfig"
process_config
process_build
cp -P libs/gstreamer-1.0/lib*.so* $LOCAL_LIB_PATH
#cp -R include/. $LOCAL_INC_PATH
cd ../../
}

build_gstpluginsbad()
{
#gstpluginsbad
mkdir gstpluginsbad
tar -xvf gst-plugins-bad-1.12.4.tar.xz --directory gstpluginsbad/
cd gstpluginsbad/gst-plugins-bad-1.12.4/
CONFIG_CMD=configure
CONFIG_PATH=./
CONFIG_PARAM=$"--host=$LOCAL_PLATFORM_PREFIX --enable-shared --libdir=$(pwd)/libs --includedir=$(pwd)/include --prefix=$(pwd) --exec-prefix=$(pwd)  --disable-x11 --disable-audiovisualizers --disable-bayer --disable-dvbsuboverlay --disable-dvdspu --disable-faceoverlay --disable-festival --disable-fieldanalysis --disable-freeverb --disable-frei0r --disable-gaudieffects --disable-geometrictransform --disable-hls --disable-inter --disable-ivfparse --disable-mxf --disable-pcapparse --disable-pnm --disable-segmentclip --disable-siren --disable-smooth --disable-speed --disable-subenc --disable-vmnc --disable-y4m --disable-directsound --disable-wasapi --disable-direct3d --disable-android_media --disable-apple_media --disable-shm --disable-vcd --disable-opensles --disable-assrender --disable-voamrwbenc --disable-voaacenc --disable-chromaprint --disable-dc1394  --disable-decklink --disable-wayland --disable-dts --disable-resindvd --disable-faac --disable-faad --disable-flite --disable-gsm --disable-ladspa --disable-lv2 --disable-libmms --disable-modplug --disable-mplex --disable-musepack --disable-neon --disable-ofa --disable-openal --disable-opencv --disable-opus --disable-rsvg --disable-teletextdec --disable-wildmidi --disable-sndfile --disable-soundtouch --disable-spc --disable-gme --disable-dvb --disable-acm --disable-vdpau --disable-zbar --disable-spandsp --disable-jp2kdecimator --disable-mpegdemux --disable-mpegpsmux --disable-mpegtsdemux --disable-mpegtsmux --disable-netsim --disable-jpegformat --disable-proxy --disable-rawparse --disable-videofilters --disable-videoparsers --disable-videosignal --disable-direct3d --disable-winscreencap --disable-midi --disable-videoframe_audiolevel --disable-sdp --disable-timecode --disable-yadif --disable-stereo --disable-librfb --disable-kms --disable-ttml --disable-examples --disable-gl --disable-gtk-doc --with-pkg-config-path=$MY_DIR/gstreamer/pkgconfig "
process_config
process_build
cp -P libs/lib*.so* $LOCAL_LIB_PATH
cp -R include/. $LOCAL_INC_PATH
cd ../../
}


build_zlib
#build_openssl
#build_nghttp2
#build_cares
#build_curl
#build_sqlite3
#build_ffi
#build_glib
#build_gstreamer
#build_gstplugin
#build_gstpluginsgood


#$LOCAL_PLATFORM_STRIP Alexa/lib/lib*

