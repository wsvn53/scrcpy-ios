//
//  ffmpeg-hw.h
//  scrcpy-core
//
//  Created by Ethan on 2021/12/11.
//

#include <libavcodec/avcodec.h>

#define avcodec_alloc_context3(...)     avcodec_alloc_context3_fix(__VA_ARGS__)

AVCodecContext *avcodec_alloc_context3_fix(const AVCodec *codec);
