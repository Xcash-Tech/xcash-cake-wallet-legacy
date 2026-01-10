#!/bin/sh

export THREADS=4
export API=21
export WORKDIR=/opt/android
export ANDROID_NDK_ZIP=${WORKDIR}/android-ndk-r20b.zip
export ANDROID_NDK_ROOT=${WORKDIR}/android-ndk-r20b
export ANDROID_NDK_HOME=$ANDROID_NDK_ROOT
export TOOLCHAIN_DIR="${WORKDIR}/toolchain"
export TOOLCHAIN_BASE_DIR=$TOOLCHAIN_DIR
export ORIGINAL_PATH=$PATH
