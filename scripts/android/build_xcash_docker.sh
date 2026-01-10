#!/bin/bash
#
# Build xcash-tech-core wallet_api library in Docker container
# Container: xcash-builder
# Target: Android arm64-v8a
#
# Prerequisites:
#   - Docker container 'xcash-builder' running with xcash-tech-core source
#   - All dependencies built in /opt/android/prefix_aarch64
#
# Usage: ./build_xcash_docker.sh
#

set -e

CONTAINER_NAME="xcash-builder"
XCASH_DIR="/opt/android/xcash-tech-core"
PREFIX_DIR="/opt/android/prefix_aarch64"
NDK_DIR="/opt/android/android-ndk-r25c"

echo "=== Building xcash-tech-core wallet_api for Android arm64-v8a ==="

# Step 1: Configure with CMake
echo ""
echo "=== Step 1: CMake Configure ==="
docker exec ${CONTAINER_NAME} bash -c "
cd ${XCASH_DIR} && \
rm -rf build && \
mkdir build && \
cd build && \
cmake .. \
  -DCMAKE_TOOLCHAIN_FILE=${NDK_DIR}/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=arm64-v8a \
  -DANDROID_PLATFORM=android-21 \
  -DCMAKE_BUILD_TYPE=Release \
  -DSTATIC=ON \
  -DBUILD_64=ON \
  -DARCH=armv8-a \
  -DANDROID:BOOL=ON \
  -DUSE_DEVICE_TREZOR=OFF \
  -DMANUAL_SUBMODULES=1 \
  -DBUILD_GUI_DEPS=1 \
  -DBUILD_TESTS=OFF \
  -DBUILD_TAG=android-armv8 \
  -DCMAKE_FIND_ROOT_PATH=${PREFIX_DIR} \
  -DOPENSSL_ROOT_DIR=${PREFIX_DIR} \
  -DOPENSSL_INCLUDE_DIR=${PREFIX_DIR}/include \
  -DOPENSSL_CRYPTO_LIBRARY=${PREFIX_DIR}/lib/libcrypto.a \
  -DOPENSSL_SSL_LIBRARY=${PREFIX_DIR}/lib/libssl.a \
  -DBOOST_ROOT=${PREFIX_DIR} \
  -DBoost_INCLUDE_DIR=${PREFIX_DIR}/include \
  -DBoost_LIBRARY_DIR=${PREFIX_DIR}/lib \
  -DBoost_NO_SYSTEM_PATHS=ON \
  -DBoost_USE_STATIC_LIBS=ON \
  -DSODIUM_LIBRARY=${PREFIX_DIR}/lib/libsodium.a \
  -DSODIUM_INCLUDE_DIR=${PREFIX_DIR}/include \
  -DZeroMQ_LIBRARY=${PREFIX_DIR}/lib/libzmq.a \
  -DZeroMQ_INCLUDE_DIR=${PREFIX_DIR}/include \
  -DZLIB_ROOT=${PREFIX_DIR} \
  -DCMAKE_INCLUDE_PATH=${PREFIX_DIR}/include
"

echo ""
echo "=== Step 2: Build wallet_api ==="
docker exec ${CONTAINER_NAME} bash -c "cd ${XCASH_DIR}/build && make -j4 wallet_api"

echo ""
echo "=== Build Complete ==="
echo "Libraries built in: ${XCASH_DIR}/lib/"
echo ""
echo "To copy libraries to host, run:"
echo "  docker cp ${CONTAINER_NAME}:${XCASH_DIR}/lib/ ./xcash-libs/"
