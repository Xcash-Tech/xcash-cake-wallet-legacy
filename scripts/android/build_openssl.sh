#!/bin/sh


set -e
set -x

. ./config.sh
OPENSSL_FILENAME=openssl-1.1.1w.tar.gz
OPENSSL_FILE_PATH=$WORKDIR/$OPENSSL_FILENAME
OPENSSL_SRC_DIR=$WORKDIR/openssl-1.1.1w
OPENSSL_SHA256="cf3098950cb4d853ad95c0841f1f9c6d3dc102dccfcacd521d93925208b76ac8"

ZLIB_DIR=$WORKDIR/zlib
ZLIB_TAG=v1.2.11
ZLIB_COMMIT_HASH="cacf7f1d4e3d44d871b605da3b647f07d718623f"

rm -rf $ZLIB_DIR
git clone -b $ZLIB_TAG --depth 1 https://github.com/madler/zlib $ZLIB_DIR
cd $ZLIB_DIR
git reset --hard $ZLIB_COMMIT_HASH

curl https://www.openssl.org/source/$OPENSSL_FILENAME -o $OPENSSL_FILE_PATH
echo $OPENSSL_SHA256 $OPENSSL_FILE_PATH | sha256sum -c - || exit 1

for arch in "aarch" "aarch64" "i686" "x86_64"
do
PREFIX=$WORKDIR/prefix_${arch}
PATH="${TOOLCHAIN_BASE_DIR}_$arch/bin:${ORIGINAL_PATH}"



case $arch in
	"aarch")   CLANG=armv7a-linux-androideabi${API}-clang
		   CXXLANG=armv7a-linux-androideabi${API}-clang++
		   X_ARCH="android-arm";;
	"aarch64") CLANG=${arch}-linux-android${API}-clang
		   CXXLANG=${arch}-linux-android${API}-clang++
		   X_ARCH="android-arm64";;
	"i686")    CLANG=${arch}-linux-android${API}-clang
		   CXXLANG=${arch}-linux-android${API}-clang++
		   X_ARCH="android-x86";;
	"x86_64")  CLANG=${arch}-linux-android${API}-clang
		   CXXLANG=${arch}-linux-android${API}-clang++
		   X_ARCH="android-x86_64";;
	*)	   CLANG=${arch}-linux-android${API}-clang
		   CXXLANG=${arch}-linux-android${API}-clang++
		   X_ARCH="android-${arch}";;
esac 	

cd $ZLIB_DIR
./configure --prefix=${PREFIX} --static
make 
make install

cd $WORKDIR
rm -rf $OPENSSL_SRC_DIR
tar -xzf $OPENSSL_FILE_PATH -C $WORKDIR
cd $OPENSSL_SRC_DIR

PATH=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin:$ANDROID_NDK_HOME/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/bin:$PATH

./Configure CC=${CLANG} CXX=${CXXLANG} ${X_ARCH} \
	no-asm no-shared --static \
	--with-zlib-include=${PREFIX}/include \
	--with-zlib-lib=${PREFIX}/lib \
	--prefix=${PREFIX} \
	--openssldir=${PREFIX} \
	-D__ANDROID_API__=$API
sed -i 's/CNF_EX_LIBS=-ldl -pthread//g;s/BIN_CFLAGS=-pie $(CNF_CFLAGS) $(CFLAGS)//g' Makefile
make -j4
make install

done

