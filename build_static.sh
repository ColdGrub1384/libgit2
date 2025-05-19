#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")"

if [ -z "$MAC_CATALYST" ]; then # iOS
    PLATFORM="$IOSSDK"
    ARCHITECTURE="$IOSARCH"
    PYTHON_DIR="iOS"
    SDK_NAME="$IOSSDK"
    
    if [ "$PLATFORM" = "iphonesimulator" ]; then
        TARGET_TRIPLE="$IOSARCH-apple-ios14.0-simulator"
    else
        TARGET_TRIPLE="$IOSARCH-apple-ios14.0"
    fi
    
    IOS_SDKROOT=$(xcrun --sdk $SDK_NAME --show-sdk-path)
else                            # Mac Catalyst
    PLATFORM="maccatalyst"
    ARCHITECTURE="$MAC_CATALYST"
    PYTHON_DIR="MacCatalyst"
    SDK_NAME="macosx"
    TARGET_TRIPLE="$ARCHITECTURE-apple-ios14.0-macabi"
    
    IOS_SDKROOT=$(xcrun --sdk macosx --show-sdk-path)
fi

export M4=$(xcrun -f m4)

source_dir=$PWD

if [ -z "$LIBSSH2_INCLUDE_DIR" ] || [ -z "LIBSSH2_LIBRARY" ]; then
    echo "Set LIBSSH2_INCLUDE_DIR and LIBSSH2_LIBRARY environment variables to compile libgit2"
    exit 1
fi

mkdir -p "build/$PLATFORM.$ARCHITECTURE"
pushd "build/$PLATFORM.$ARCHITECTURE"
cmake $source_dir \
    -DREGEX_BACKEND=builtin -DBUILD_CLAR=OFF -DBUILD_TESTS=OFF -DUSE_SSH=ON -DBUILD_EXAMPLES=OFF -DBUILD_SHARED_LIBS=OFF -DTHREADSAFE=OFF\
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_INSTALL_PREFIX=@rpath \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_OSX_SYSROOT=${IOS_SDKROOT} \
    -DCMAKE_C_COMPILER=$(xcrun --sdk $SDK_NAME -f clang) \
    -DCMAKE_C_FLAGS="-D_Debug=1 -arch $ARCHITECTURE -target $TARGET_TRIPLE -O2 -I${source_dir}" \
    -DCMAKE_MODULE_LINKER_FLAGS="-arch $ARCHITECTURE -target $TARGET_TRIPLE -O2 -undefined dynamic_lookup" \
    -DCMAKE_SHARED_LINKER_FLAGS="-arch $ARCHITECTURE -target $TARGET_TRIPLE -O2 -undefined dynamic_lookup" \
    -DCMAKE_EXE_LINKER_FLAGS="-arch $ARCHITECTURE -target $TARGET_TRIPLE -O2 -undefined dynamic_lookup" \
    -DCMAKE_LIBRARY_PATH=${IOS_SDKROOT}/lib/ \
    -DCMAKE_INCLUDE_PATH="${LIBSSH2_INCLUDE_DIR};${IOS_SDKROOT}/include/" \
    -DLIBSSH2_LIBRARY="${LIBSSH2_LIBRARY}"
make

if [ "$ARCHITECTURE" = "arm64" ]; then
    (find "src/libgit2/CMakeFiles/libgit2.dir" -name "*.o" -exec lipo -remove x86_64 "{}" -o "{}" \;) &> /dev/null
else
    (find "src/libgit2/CMakeFiles/libgit2.dir" -name "*.o" -exec lipo -remove arm64 "{}" -o "{}" \;) &> /dev/null
fi

rm "libgit2.a"

find "src/libgit2/CMakeFiles/libgit2.dir" -name "*.o" | xargs ar r "libgit2.a"
