#!/bin/bash
set -e
set -x

export THREADS=${THREADS:-8}
export API=21
export WORKDIR=/opt/android
export ANDROID_NDK_ROOT=${WORKDIR}/android-ndk-r25c
export ANDROID_NDK_HOME=${ANDROID_NDK_ROOT}
export ANDROID_SDK_ROOT=${WORKDIR}/sdk
export ORIGINAL_PATH=$PATH
export CW_DIR=${WORKDIR}/cake_wallet

# Detect host architecture
HOST_ARCH=$(uname -m)
if [ "$HOST_ARCH" = "aarch64" ] || [ "$HOST_ARCH" = "arm64" ]; then
    export HOST_TAG="linux-aarch64"
else
    export HOST_TAG="linux-x86_64"
fi

# NDK r25c uses unified toolchain
export TOOLCHAIN=${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/${HOST_TAG}
export PATH="${TOOLCHAIN}/bin:${ORIGINAL_PATH}"

echo "=== XCash CakeWallet Build Script ==="
echo "Using ${THREADS} threads for compilation"
echo "Host architecture: ${HOST_ARCH}"
echo "NDK toolchain: ${TOOLCHAIN}"
echo ""

cd ${CW_DIR}

# ============================================
# Step 1: Clone xcash-tech-core
# ============================================
echo "=== Cloning xcash-tech-core ==="
MONERO_SRC_DIR=${WORKDIR}/xcash

if [ ! -d "$MONERO_SRC_DIR" ]; then
    git clone https://github.com/Xcash-Tech/xcash-tech-core.git ${MONERO_SRC_DIR}
    cd $MONERO_SRC_DIR
    git submodule init
    git submodule update
fi

# ============================================
# Step 2: Build dependencies (only arm64 for faster build)
# ============================================
echo "=== Building dependencies for arm64 ==="

# Only build for aarch64 (arm64-v8a) to speed up the build
ARCHS="aarch64"

# Create prefix directories
for arch in ${ARCHS}; do
    mkdir -p ${WORKDIR}/prefix_${arch}/lib ${WORKDIR}/prefix_${arch}/include
done

build_zlib() {
    local arch=$1
    local PREFIX=${WORKDIR}/prefix_${arch}
    
    echo "=== Building zlib for ${arch} ==="
    
    cd ${WORKDIR}
    if [ ! -d "zlib" ]; then
        git clone -b v1.2.11 --depth 1 https://github.com/madler/zlib zlib
    fi
    
    cd zlib
    make distclean || make clean || true
    
    case $arch in
        "aarch64") 
            export CC="${TOOLCHAIN}/bin/aarch64-linux-android${API}-clang"
            export AR="${TOOLCHAIN}/bin/llvm-ar"
            export RANLIB="${TOOLCHAIN}/bin/llvm-ranlib"
            ;;
    esac
    
    # zlib configure is sensitive to warnings, disable -Werror
    export CFLAGS="-O2 -Wno-error"
    export LDFLAGS=""
    ./configure --prefix=${PREFIX} --static
    make -j${THREADS}
    make install
    unset CC AR RANLIB CFLAGS
}

build_openssl() {
    local arch=$1
    local PREFIX=${WORKDIR}/prefix_${arch}
    
    echo "=== Building OpenSSL for ${arch} ==="
    
    cd ${WORKDIR}
    
    OPENSSL_VERSION="1.1.1w"
    if [ ! -f "openssl-${OPENSSL_VERSION}.tar.gz" ]; then
        curl -LO https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz
    fi
    
    rm -rf openssl-${OPENSSL_VERSION}
    tar -xzf openssl-${OPENSSL_VERSION}.tar.gz
    cd openssl-${OPENSSL_VERSION}
    
    case $arch in
        "aarch64") 
            TARGET="android-arm64"
            ;;
    esac
    
    ./Configure ${TARGET} \
        -D__ANDROID_API__=${API} \
        --prefix=${PREFIX} \
        --openssldir=${PREFIX} \
        no-asm no-shared --static \
        --with-zlib-include=${PREFIX}/include \
        --with-zlib-lib=${PREFIX}/lib
    
    make -j${THREADS}
    make install_sw
}

build_sodium() {
    local arch=$1
    local PREFIX=${WORKDIR}/prefix_${arch}
    
    echo "=== Building libsodium for ${arch} ==="
    
    cd ${WORKDIR}
    
    SODIUM_VERSION="1.0.18"
    if [ ! -f "libsodium-${SODIUM_VERSION}.tar.gz" ]; then
        curl -LO https://download.libsodium.org/libsodium/releases/libsodium-${SODIUM_VERSION}.tar.gz
    fi
    
    rm -rf libsodium-${SODIUM_VERSION}
    tar -xzf libsodium-${SODIUM_VERSION}.tar.gz
    cd libsodium-${SODIUM_VERSION}
    
    case $arch in
        "aarch64")
            HOST="aarch64-linux-android"
            export CC="${TOOLCHAIN}/bin/aarch64-linux-android${API}-clang"
            export CXX="${TOOLCHAIN}/bin/aarch64-linux-android${API}-clang++"
            ;;
    esac
    
    ./configure --prefix=${PREFIX} --host=${HOST} --disable-shared --enable-static
    make -j${THREADS}
    make install
    unset CC CXX
}

build_boost() {
    local arch=$1
    local PREFIX=${WORKDIR}/prefix_${arch}
    
    echo "=== Building Boost for ${arch} ==="
    
    cd ${WORKDIR}
    
    BOOST_VERSION="1_74_0"
    BOOST_DOT_VERSION="1.74.0"
    
    if [ ! -f "boost_${BOOST_VERSION}.tar.gz" ]; then
        curl -LO https://boostorg.jfrog.io/artifactory/main/release/${BOOST_DOT_VERSION}/source/boost_${BOOST_VERSION}.tar.gz
    fi
    
    rm -rf boost_${BOOST_VERSION}
    tar -xzf boost_${BOOST_VERSION}.tar.gz
    cd boost_${BOOST_VERSION}
    
    case $arch in
        "aarch64")
            export CC="${TOOLCHAIN}/bin/aarch64-linux-android${API}-clang"
            export CXX="${TOOLCHAIN}/bin/aarch64-linux-android${API}-clang++"
            BOOST_ARCH="arm"
            BOOST_ABI="aapcs"
            ;;
    esac
    
    ./bootstrap.sh --prefix=${PREFIX}
    
    cat > user-config.jam << EOF
using clang : android : ${CXX} ;
EOF
    
    ./b2 -j${THREADS} \
        --user-config=user-config.jam \
        toolset=clang-android \
        target-os=android \
        architecture=${BOOST_ARCH} \
        abi=${BOOST_ABI} \
        link=static \
        threading=multi \
        --with-chrono \
        --with-date_time \
        --with-filesystem \
        --with-program_options \
        --with-regex \
        --with-serialization \
        --with-system \
        --with-thread \
        --with-locale \
        --prefix=${PREFIX} \
        install
    
    unset CC CXX
}

build_zmq() {
    local arch=$1
    local PREFIX=${WORKDIR}/prefix_${arch}
    
    echo "=== Building ZeroMQ for ${arch} ==="
    
    cd ${WORKDIR}
    
    ZMQ_VERSION="4.3.4"
    if [ ! -f "zeromq-${ZMQ_VERSION}.tar.gz" ]; then
        curl -LO https://github.com/zeromq/libzmq/releases/download/v${ZMQ_VERSION}/zeromq-${ZMQ_VERSION}.tar.gz
    fi
    
    rm -rf zeromq-${ZMQ_VERSION}
    tar -xzf zeromq-${ZMQ_VERSION}.tar.gz
    cd zeromq-${ZMQ_VERSION}
    
    case $arch in
        "aarch64")
            HOST="aarch64-linux-android"
            export CC="${TOOLCHAIN}/bin/aarch64-linux-android${API}-clang"
            export CXX="${TOOLCHAIN}/bin/aarch64-linux-android${API}-clang++"
            ;;
    esac
    
    ./configure --prefix=${PREFIX} --host=${HOST} \
        --disable-shared --enable-static \
        --with-libsodium=${PREFIX}
    
    make -j${THREADS}
    make install
    unset CC CXX
}

build_xcash_core() {
    local arch=$1
    local PREFIX=${WORKDIR}/prefix_${arch}
    
    echo "=== Building xcash-tech-core for ${arch} ==="
    
    cd ${WORKDIR}/xcash
    
    case $arch in
        "aarch64")
            export CC="${TOOLCHAIN}/bin/aarch64-linux-android${API}-clang"
            export CXX="${TOOLCHAIN}/bin/aarch64-linux-android${API}-clang++"
            export AR="${TOOLCHAIN}/bin/llvm-ar"
            export RANLIB="${TOOLCHAIN}/bin/llvm-ranlib"
            CMAKE_ARCH="aarch64"
            ;;
    esac
    
    rm -rf build_${arch}
    mkdir -p build_${arch}
    cd build_${arch}
    
    cmake .. \
        -DCMAKE_TOOLCHAIN_FILE=${ANDROID_NDK_ROOT}/build/cmake/android.toolchain.cmake \
        -DANDROID_ABI=arm64-v8a \
        -DANDROID_NATIVE_API_LEVEL=${API} \
        -DCMAKE_BUILD_TYPE=Release \
        -DSTATIC=ON \
        -DBUILD_SHARED_LIBS=OFF \
        -DBUILD_TESTS=OFF \
        -DBUILD_GUI_DEPS=ON \
        -DUSE_DEVICE_TREZOR=OFF \
        -DMANUAL_SUBMODULES=1 \
        -DBOOST_ROOT=${PREFIX} \
        -DOPENSSL_ROOT_DIR=${PREFIX} \
        -DOPENSSL_INCLUDE_DIR=${PREFIX}/include \
        -DOPENSSL_CRYPTO_LIBRARY=${PREFIX}/lib/libcrypto.a \
        -DOPENSSL_SSL_LIBRARY=${PREFIX}/lib/libssl.a \
        -DZeroMQ_DIR=${PREFIX} \
        -DCMAKE_INSTALL_PREFIX=${PREFIX}
    
    make -j${THREADS} wallet_api
    
    # Copy built libraries
    mkdir -p ${CW_DIR}/cw_monero/android/libs/arm64-v8a
    find . -name "*.a" -exec cp {} ${CW_DIR}/cw_monero/android/libs/arm64-v8a/ \;
    
    unset CC CXX AR RANLIB
}

# Build all dependencies
for arch in ${ARCHS}; do
    build_zlib ${arch}
    build_openssl ${arch}
    build_sodium ${arch}
    build_boost ${arch}
    build_zmq ${arch}
    build_xcash_core ${arch}
done

# ============================================
# Step 3: Build Flutter APK
# ============================================
echo "=== Building Flutter APK ==="

cd ${CW_DIR}

# Configure Flutter
export PATH="/opt/flutter/bin:${ORIGINAL_PATH}"
flutter config --no-analytics
flutter doctor

# Get dependencies
flutter pub get

# Generate code if needed
if [ -f "tool/generate_secrets_config.dart" ]; then
    dart run tool/generate_secrets_config.dart || true
fi

# Build APK for arm64 only
flutter build apk --release --target-platform android-arm64

echo ""
echo "=== Build Complete ==="
echo "APK location: ${CW_DIR}/build/app/outputs/flutter-apk/app-release.apk"
ls -la ${CW_DIR}/build/app/outputs/flutter-apk/ 2>/dev/null || echo "APK not found in expected location"
