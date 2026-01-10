#!/bin/sh

ARCH=$1
PREFIX=$2
BOOST_SRC_DIR=$3

cd $BOOST_SRC_DIR

./b2 --build-type=minimal link=static runtime-link=static --with-chrono --with-date_time --with-filesystem --with-program_options --with-regex --with-serialization --with-system --with-thread --with-locale --build-dir=android --stagedir=android toolset=clang threading=multi threadapi=pthread target-os=android cxxflags="-std=gnu++11 -Wno-enum-constexpr-conversion" define=BOOST_NO_CXX98_FUNCTION_BASE -sICONV_PATH=${PREFIX} install
