//
//  ffmpeg-hw.c
//  scrcpy-core
//
//  Created by Ethan on 2021/12/11.
//

#include <libavcodec/avcodec.h>
@import Foundation;

static void fix_create_hwctx(AVCodecContext *context) {
    AVBufferRef *codec_buf;
    const char *codecName = av_hwdevice_get_type_name(AV_HWDEVICE_TYPE_VIDEOTOOLBOX);
    enum AVHWDeviceType type = av_hwdevice_find_type_by_name(codecName);
    int err = av_hwdevice_ctx_create(&codec_buf, type, NULL, NULL, 0);
    if (err < 0) {
        NSLog(@"[ERROR] Init Hardware Decoder FAILED, Fallback to Software Decoder.");
        return;
    }
    context->hw_device_ctx = av_buffer_ref(codec_buf);
}

AVCodecContext *avcodec_alloc_context3_fix(const AVCodec *codec) {
    AVCodecContext *context = avcodec_alloc_context3(codec);
    fix_create_hwctx(context);
    return context;
}
