scrcpy-server:
	curl -o scrcpy-server/scrcpy-server -L https://github.com/Genymobile/scrcpy/releases/download/v1.18/scrcpy-server-v1.18 

libsdl:
	OUTPUT=$$(pwd)/Libs ./Scripts/build-libsdl.sh

ffmpeg:
	cd Libs && curl -O -L https://downloads.sourceforge.net/project/ffmpeg-ios/ffmpeg-ios-master.tar.bz2
	cd Libs && bunzip2 ffmpeg-ios*.bz2
	cd Libs && tar xvf ffmpeg-ios*.tar
	cd Libs && cp -av FFmpeg-iOS/include/* include
	cd Libs && cp -av FFmpeg-iOS/lib/* lib
	cd Libs && rm -rf FFmpeg-iOS README.md ffmpeg-*

scrcpy-init: libsdl ffmpeg
	# generate config.h
	cd scrcpy-src && meson x --buildtype release --strip -Db_lto=true
	# fix build issues
	# -> remove windows platform code
	rm -v scrcpy-src/app/src/sys/win/process.c

.PHONY: scrcpy-server