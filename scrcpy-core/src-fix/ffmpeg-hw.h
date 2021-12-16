//
//  ffmpeg-hw.h
//  scrcpy-core
//
//  Created by Ethan on 2021/12/11.
//

#include <libavcodec/avcodec.h>

#define avcodec_alloc_context3(...)     avcodec_alloc_context3_fix(__VA_ARGS__)
#define avcodec_send_packet(...)     avcodec_send_packet_fix(__VA_ARGS__)

// handle avcodec_alloc_context3 to create hardware decode context
AVCodecContext *avcodec_alloc_context3_fix(const AVCodec *codec);

// handle avcodec_send_packet to fix hardware decode issues when enter to background
int avcodec_send_packet_fix(AVCodecContext *avctx, const AVPacket *avpkt);
