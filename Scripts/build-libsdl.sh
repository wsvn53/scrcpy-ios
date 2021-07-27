#!/bin/bash

set -x;

BUILD_DIR=$(mktemp -d -t SDL);
cd $BUILD_DIR;

curl -O https://www.libsdl.org/release/SDL2-2.0.14.tar.gz;
tar xzvf SDL*.tar.gz;

sed -i '' "s#0.000002#0.016#g" SDL*/src/video/uikit/SDL_uikitevents.m;
grep "CFTimeInterval seconds" SDL*/src/video/uikit/SDL_uikitevents.m;

xcodebuild clean build OTHER_CFLAGS="-fembed-bitcode" \
	BUILD_DIR=$BUILD_DIR/build \
	ARCHS="arm64" \
	CONFIGURATION=Release \
	-project SDL2-*/Xcode/SDL/SDL.xcodeproj -scheme "Static Library-iOS" -sdk iphoneos;
xcodebuild clean build OTHER_CFLAGS="-fembed-bitcode" \
	BUILD_DIR=$BUILD_DIR/build \
	ARCHS="x86_64" \
	CONFIGURATION=Release \
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