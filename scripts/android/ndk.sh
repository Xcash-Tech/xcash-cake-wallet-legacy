#!/bin/sh

. ./config.sh
TOOLCHAIN_DIR=${WORKDIR}/toolchain
TOOLCHAIN_A32_DIR=${TOOLCHAIN_DIR}_aarch
TOOLCHAIN_A64_DIR=${TOOLCHAIN_DIR}_aarch64
TOOLCHAIN_x86_DIR=${TOOLCHAIN_DIR}_i686
TOOLCHAIN_x86_64_DIR=${TOOLCHAIN_DIR}_x86_64
ANDROID_NDK_SHA1="fdf33d9f6c1b3f16e5459d53a82c7d2201edbcc4"

python3 ${ANDROID_NDK_ROOT}/build/tools/make_standalone_toolchain.py --arch arm64 --api $API --install-dir ${TOOLCHAIN_A64_DIR} --stl=libc++
python3 ${ANDROID_NDK_ROOT}/build/tools/make_standalone_toolchain.py --arch arm --api $API --install-dir ${TOOLCHAIN_A32_DIR} --stl=libc++
python3 ${ANDROID_NDK_ROOT}/build/tools/make_standalone_toolchain.py --arch x86 --api $API --install-dir ${TOOLCHAIN_x86_DIR} --stl=libc++
python3 ${ANDROID_NDK_ROOT}/build/tools/make_standalone_toolchain.py --arch x86_64 --api $API --install-dir ${TOOLCHAIN_x86_64_DIR} --stl=libc++
