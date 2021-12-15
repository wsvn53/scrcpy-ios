all: libsdl ffmpeg libssh scrcpy-init

libsdl:
	OUTPUT=$$(pwd)/Libs ./Scripts/build-libsdl.sh

ffmpeg:
	cd Libs && curl -O -L https://downloads.sourceforge.net/project/ffmpeg-ios/ffmpeg-ios-master.tar.bz2
	cd Libs && bunzip2 ffmpeg-ios*.bz2
	cd Libs && tar xvf ffmpeg-ios*.tar
	cd Libs && cp -av FFmpeg-iOS/include/* include
	cd Libs && cp -av FFmpeg-iOS/lib/* lib
	cd Libs && rm -rf FFmpeg-iOS README.md ffmpeg-*

libssh:
	make -C ssh

scrcpy-init:
	# checkout scrcpy sources
	git submodule update --init --recursive
	# generate config.h
	cd scrcpy-src && meson x --buildtype release --strip -Db_lto=true
	# fix build issues
	# -> remove windows platform code
	rm -v scrcpy-src/app/src/sys/win/process.c || echo "=> ALREADY REMOVED"

.PHONY: scrcpy-server
