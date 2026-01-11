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
HOST_XCASH_DIR="/opt/android/cake_wallet/external/xcash-tech-core"
PREFIX_DIR="/opt/android/prefix_aarch64"
NDK_DIR="/opt/android/android-ndk-r25c"
DEST_BASE="/opt/android/cake_wallet/cw_monero/ios/External/android/arm64-v8a"

echo "=== Building xcash-tech-core wallet_api for Android arm64-v8a ==="

# Step 0: Sync core sources from mounted CakeWallet repo (if present)
echo ""
echo "=== Step 0: Sync xcash-tech-core sources ==="
docker exec ${CONTAINER_NAME} bash -lc "
if [ -d \"${HOST_XCASH_DIR}\" ]; then
  echo \"Syncing from ${HOST_XCASH_DIR} -> ${XCASH_DIR}\";
  rm -rf \"${XCASH_DIR}\";
  cp -a \"${HOST_XCASH_DIR}\" \"${XCASH_DIR}\";
else
  echo \"${HOST_XCASH_DIR} not found; using existing ${XCASH_DIR}\";
fi
"

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
echo "=== Step 3: Copy wallet libs to CakeWallet ==="
docker exec ${CONTAINER_NAME} bash -lc "
set -e
DEST_LIB='${DEST_BASE}/lib/monero'
DEST_INCLUDE='${DEST_BASE}/include'
mkdir -p \"\${DEST_LIB}\" \"\${DEST_INCLUDE}\"

cp -f '${XCASH_DIR}/build/lib/libwallet_api.a' \"\${DEST_LIB}/libwallet_api.a\"
cp -f '${XCASH_DIR}/build/lib/libwallet.a' \"\${DEST_LIB}/libwallet.a\"
cp -f '${XCASH_DIR}/src/wallet/api/wallet2_api.h' \"\${DEST_INCLUDE}/wallet2_api.h\"

ls -la \"\${DEST_LIB}/libwallet_api.a\" \"\${DEST_LIB}/libwallet.a\" \"\${DEST_INCLUDE}/wallet2_api.h\"
"

echo ""
echo "=== Build Complete ==="
echo "Libraries built in: ${XCASH_DIR}/lib/"
echo ""
echo "To copy libraries to host, run:"
echo "  docker cp ${CONTAINER_NAME}:${XCASH_DIR}/lib/ ./xcash-libs/"
