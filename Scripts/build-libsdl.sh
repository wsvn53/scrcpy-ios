#!/bin/bash

set -x;

BUILD_DIR=$(mktemp -d -t SDL);
cd $BUILD_DIR;

curl -O https://www.libsdl.org/release/SDL2-2.0.16.tar.gz;
tar xzvf SDL*.tar.gz;

xcodebuild clean build OTHER_CFLAGS="-fembed-bitcode" \
	BUILD_DIR=$BUILD_DIR/build \
	ARCHS="arm64" \
	CONFIGURATION=Release \
	GCC_PREPROCESSOR_DEFINITIONS='CFRunLoopRunInMode=CFRunLoopRunInMode_fix' \
	-project SDL2-*/Xcode/SDL/SDL.xcodeproj -scheme "Static Library-iOS" -sdk iphoneos;
xcodebuild clean build OTHER_CFLAGS="-fembed-bitcode" \
	BUILD_DIR=$BUILD_DIR/build \
	ARCHS="x86_64" \
	CONFIGURATION=Release \
	GCC_PREPROCESSOR_DEFINITIONS='CFRunLoopRunInMode=CFRunLoopRunInMode_fix' \
	-project SDL2-*/Xcode/SDL/SDL.xcodeproj -scheme "Static Library-iOS" -sdk iphonesimulator;

lipo -create build/*/libSDL2.a -output build/libSDL2.a;
file build/libSDL2.a;

[[ -d "$OUTPUT/lib" ]] || mkdir -pv "$OUTPUT/lib";
[[ -d "$OUTPUT/include/SDL2" ]] || mkdir -pv $OUTPUT/include/SDL2;
[[ -d "$OUTPUT" ]] && {
	[[ -d "$OUTPUT/lib" ]] && cp -v build/libSDL2.a $OUTPUT/lib;
	[[ -d "$OUTPUT/include" ]] && cp -v SDL2-*/include/*.h $OUTPUT/include/SDL2;
}

[[ -d "$BUILD_DIR" ]] && rm -rf $BUILD_DIR;
