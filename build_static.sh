#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")"

if [ -z "$MAC_CATALYST" ]; then # iOS
    PLATFORM="iphoneos"
    ARCHITECTURE="arm64"
    PYTHON_DIR="iOS"
    SDK_NAME="iphoneos"
    TARGET_TRIPLE="arm64-apple-darwin19.6.0"
    
    IOS_SDKROOT=$(xcrun --sdk iphoneos --show-sdk-path)
else                            # Mac Catalyst
    PLATFORM="maccatalyst"
    ARCHITECTURE="$MAC_CATALYST"
    PYTHON_DIR="MacCatalyst"
    SDK_NAME="macosx"
    TARGET_TRIPLE="$ARCHITECTURE-apple-ios13.1-macabi"
    
    IOS_SDKROOT=$(xcrun --sdk macosx --show-sdk-path)
fi

export M4=$(xcrun -f m4)

source_dir=$PWD

export LIBSSH2_INCLUDE_DIR="${source_dir}/../libssh2/libssh2/include"
export LIBSSH2_LIBRARY="${source_dir}/../libssh2/build-$PLATFORM.$ARCHITECTURE/src/libssh2.a"

mkdir -p "build-$PLATFORM.$ARCHITECTURE"
pushd "build-$PLATFORM.$ARCHITECTURE"
cmake $source_dir \
    -DREGEX_BACKEND=builtin -DBUILD_CLAR=OFF -DBUILD_TESTS=OFF -DUSE_SSH=ON -DBUILD_EXAMPLES=OFF -DBUILD_SHARED_LIBS=OFF -DTHREADSAFE=OFF\
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_INSTALL_PREFIX=@rpath \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_OSX_SYSROOT=${IOS_SDKROOT} \
    -DCMAKE_C_COMPILER=$(xcrun --sdk $SDK_NAME -f clang) \
    -DCMAKE_C_FLAGS="-D_Debug=1 -arch $ARCHITECTURE -target $TARGET_TRIPLE -O2 -miphoneos-version-min=14 -I${source_dir}" \
    -DCMAKE_MODULE_LINKER_FLAGS="-arch $ARCHITECTURE -target $TARGET_TRIPLE -O2 -miphoneos-version-min=14 -undefined dynamic_lookup" \
    -DCMAKE_SHARED_LINKER_FLAGS="-arch $ARCHITECTURE -target $TARGET_TRIPLE -O2 -miphoneos-version-min=14 -undefined dynamic_lookup" \
    -DCMAKE_EXE_LINKER_FLAGS="-arch $ARCHITECTURE -target $TARGET_TRIPLE -O2 -miphoneos-version-min=14 -undefined dynamic_lookup" \
    -DCMAKE_LIBRARY_PATH=${IOS_SDKROOT}/lib/ \
    -DCMAKE_INCLUDE_PATH="${LIBSSH2_INCLUDE_DIR};${IOS_SDKROOT}/include/" \
    -DLIBSSH2_LIBRARY="${LIBSSH2_LIBRARY}"
make
