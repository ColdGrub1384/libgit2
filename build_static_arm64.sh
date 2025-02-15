#!/bin/bash

# M4 Required with Xcode beta:
export M4=$(xcrun -f m4)
IOS_SDKROOT=$(xcrun --sdk iphoneos --show-sdk-path)

source_dir=$PWD

export LIBSSH2_INCLUDE_DIR="${source_dir}/../libssh2/libssh2/libssh2"
export LIBSSH2_LIBRARY="${source_dir}/../libssh2/libssh2.a"

mkdir -p build-iphoneos
pushd build-iphoneos
cmake $source_dir \
    -DREGEX_BACKEND=builtin -DBUILD_CLAR=OFF -DBUILD_TESTS=OFF -DUSE_SSH=ON -DBUILD_EXAMPLES=OFF -DBUILD_SHARED_LIBS=OFF -DTHREADSAFE=OFF\
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_INSTALL_PREFIX=@rpath \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_OSX_SYSROOT=${IOS_SDKROOT} \
    -DCMAKE_C_COMPILER=$(xcrun --sdk iphoneos -f clang) \
    -DCMAKE_C_FLAGS="-D_Debug=1 -arch arm64 -target arm64-apple-darwin19.6.0 -O2 -miphoneos-version-min=14 -I${source_dir}" \
    -DCMAKE_MODULE_LINKER_FLAGS="-arch arm64 -target arm64-apple-darwin19.6.0 -O2 -miphoneos-version-min=14 -undefined dynamic_lookup" \
    -DCMAKE_SHARED_LINKER_FLAGS="-arch arm64 -target arm64-apple-darwin19.6.0 -O2 -miphoneos-version-min=14 -undefined dynamic_lookup" \
    -DCMAKE_EXE_LINKER_FLAGS="-arch arm64 -target arm64-apple-darwin19.6.0 -O2 -miphoneos-version-min=14 -undefined dynamic_lookup" \
    -DCMAKE_LIBRARY_PATH=${IOS_SDKROOT}/lib/ \
    -DCMAKE_INCLUDE_PATH="${LIBSSH2_INCLUDE_DIR};${IOS_SDKROOT}/include/" \
    -DLIBSSH2_LIBRARY="${LIBSSH2_LIBRARY}"
make
