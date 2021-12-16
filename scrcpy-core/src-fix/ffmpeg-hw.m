//
//  ffmpeg-hw.c
//  scrcpy-core
//
//  Created by Ethan on 2021/12/11.
//

#include <libavcodec/avcodec.h>
@import Foundation;
#import <SDL2/SDL_events.h>

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

#import "input_manager.h"
bool input_manager_handle_event_fix(struct input_manager *im, SDL_Event *event);

int avcodec_send_packet_fix(AVCodecContext *avctx, const AVPacket *avpkt) {
    int ret = avcodec_send_packet(avctx, avpkt);
    
    static NSTimeInterval last_restart = 0;
    if (ret < 0 && CFAbsoluteTimeGetCurrent() - last_restart > 1.0) {
        SDL_Keysym keySym;
        keySym.scancode = SDL_SCANCODE_END;
        keySym.sym = SDLK_END;
        keySym.mod = 0;
        keySym.unused = 1;
        
        SDL_KeyboardEvent keyEvent;
        keyEvent.type = SDL_KEYUP;
        keyEvent.state = SDL_PRESSED;
        keyEvent.repeat = '\0';
        keyEvent.keysym = keySym;
        
        SDL_Event event;
        event.type = keyEvent.type;
        event.key = keyEvent;
        
        input_manager_handle_event_fix(NULL, &event);
        last_restart = CFAbsoluteTimeGetCurrent();
    }
    
    // always return 0
    return 0;
}
