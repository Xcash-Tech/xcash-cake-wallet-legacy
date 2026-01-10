#!/bin/sh

. ./config.sh
ZMQ_SRC_DIR=$WORKDIR/libzmq
ZMQ_BRANCH=v4.3.3
ZMQ_COMMIT_HASH=622fc6dde99ee172ebaa9c8628d85a7a1995a21d


rm -rf $ZMQ_SRC_DIR
git clone https://github.com/zeromq/libzmq.git ${ZMQ_SRC_DIR} -b ${ZMQ_BRANCH}
cd $ZMQ_SRC_DIR
git checkout $ZMQ_BRANCH


for arch in "aarch" "aarch64" "i686" "x86_64"
do

PREFIX=$WORKDIR/prefix_${arch}
PATH="${TOOLCHAIN_BASE_DIR}_${arch}/bin:${ORIGINAL_PATH}"


case $arch in
	"aarch"	) TARGET="arm";;
	"aarch64"	) TARGET="arm64";;
	"i686"		) TARGET="x86";;
	"x86_64"		) TARGET="x86_64";;
	*		) TARGET="${arch}";;
esac 

cd $ZMQ_SRC_DIR/builds/android/
./build.sh "${TARGET}"

cp -r $ZMQ_SRC_DIR/builds/android/.build/prefix/$TARGET/* $PREFIX

done
