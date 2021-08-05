//
//  fix.c
//  libscrcpy
//
//  Created by Ethan on 2021/7/7.
//

#import "fix.h"
#import <stdbool.h>
#import <util/process.h>
#import <util/net.h>
#import "ssh.h"
#import <SDL2/SDL.h>
#import <SDL2/SDL_render.h>
#import "utils.h"
#import "util/thread.h"
#import "ExecStatus.h"

// headers required by PeepEvents
#import "events.h"
#import "screen.h"
#import "input_manager.h"

@import CoreMedia;
@import CoreVideo;
@import VideoToolbox;
@import AVFoundation;

// control wait-server thread exit
static bool bScrcpyServerStopControl = false;
// control peepEvent thread
static bool bScrcpyPeepEventStopControl = false;
// control use Hardware decoder first
static bool bScrcpyUseHardwareDecoder = true;

// handle is_regular_file to ignore check local scrcpy-server exists
bool
is_regular_file(const char *path) {
    printf("=> is_regular_file: %s\n", path);
    return true;
}

// handle process_result to use ssh_exec
enum process_result
process_execute(const char *const argv[], pid_t *pid) {
    *pid = 1000;
    return ssh_exec(argv);
}

// handle process_check_success to always true
bool
process_check_success(process_t proc, const char *name, bool close) {
    printf("> process_check_success: %s\n", name);
    if (proc < 0) return false;
    return [[ExecStatus sharedStatus] checkSuccess:name];
}

void process_wait_reset(void) {
    bScrcpyServerStopControl = false;
    reset_PeepEvents();
}

void process_wait_stop(void) {
    bScrcpyServerStopControl = true;
    stop_PeepEvents();
}

// handle process_wait to forbidden scrcpy exit
exit_code_t
process_wait(pid_t pid, bool close) {
    // use sleep to fake wait status
    while (bScrcpyServerStopControl == false) {
        sleep(2);
    }
    bScrcpyServerStopControl = false;
    return 0;
}

// handle sc_thread_join to stop wait-server thread
void
sc_thread_join(sc_thread *thread, int *status) {
    bScrcpyServerStopControl = true;
}

// handle SDL_CreateRenderer to set scale
SDL_Renderer * SDL_CreateRenderer_fix(SDL_Window * window, int index, Uint32 flags) {
    SDL_Renderer *renderer = SDL_CreateRenderer(window, index, flags);
    SDL_RenderSetScale(renderer, screen_scale(), screen_scale());
    [NSNotificationCenter.defaultCenter postNotificationName:kSDLDidCreateRendererNotification object:nil];
    return renderer;
}

/**
 Section: Handle PeedEvents
 > scrcpy using loop_event method to handle events and response UI task, but it causing high CPU load on main thread;
 
 So, the SOLUTION is:
 - Modify libSDL code to modify the CFRunLoop duration to 0.016s, to make sure we can rendering at 60FPS, see Scripts/libsdl.sh
 - Hook SDL_WaitEvent to start a PeepEvents thread, in order to continue send user's interactions to Android
 - Add compiler flag to redirect <screen_handle_event> to <screen_handle_event_fix> handle [screen] pointer
 - Add compiler flag to redirect <input_manager_handle_event> to <input_manager_handle_event_fix> handle [input_manger] pointer
*/

enum event_result {
    EVENT_RESULT_CONTINUE,
    EVENT_RESULT_STOPPED_BY_USER,
    EVENT_RESULT_STOPPED_BY_EOS,
};

// hook screen_handle_event to handle "screen" object
bool screen_handle_event_fix(struct screen *screen, SDL_Event *event) {
    static struct screen *screen_ref = NULL;
    
    // save screen reference for handle_event use
    screen_ref = screen == NULL ? screen_ref : screen;
    // retrieve screen if screen not passed in
    screen = screen == NULL ? screen_ref : screen;
    
    // if screen finally is null, do nothing
    if (screen == NULL) return false;
    
    return screen_handle_event(screen, event);
}

// hook input_manager_handle_event to handle "input_manager" object
bool input_manager_handle_event_fix(struct input_manager *im, SDL_Event *event) {
    static struct input_manager *im_ref = NULL;
    
    // save im reference for handle event use
    im_ref = im == NULL ? im_ref : im;
    // retrieve im if im not passed in
    im = im == NULL ? im_ref : im;
    
    // if im finally is null, do nothing
    if (im == NULL) return false;
    
    return input_manager_handle_event(im, event);
}

// this function is copying from scrcpy.c
enum event_result handle_event_fix(SDL_Event *event) {
    switch (event->type) {
        case EVENT_STREAM_STOPPED:
            NSLog(@"Video stream stopped");
            return EVENT_RESULT_STOPPED_BY_EOS;
        case SDL_QUIT:
            NSLog(@"User requested to quit");
            return EVENT_RESULT_STOPPED_BY_USER;
        case SDL_DROPFILE: {
            // IGNORE here, iOS version donot need drop file feature
            goto end;
        }
    }

    bool consumed = screen_handle_event_fix(NULL, event);
    if (consumed) {
        goto end;
    }

    consumed = input_manager_handle_event_fix(NULL, event);
    (void) consumed;

end:
    return EVENT_RESULT_CONTINUE;
}

void handle_event_main(SDL_Event *event) {
    dispatch_sync(dispatch_get_main_queue(), ^{
        handle_event_fix(event);
    });
}

// Hack PeepEvents
void reset_PeepEvents (void) {
    bScrcpyPeepEventStopControl = false;
}

void stop_PeepEvents (void) {
    bScrcpyPeepEventStopControl = true;
}

void handle_PeepEvents(void) {
    while (bScrcpyPeepEventStopControl == false) {
        SDL_Event event;
        int ret = SDL_PeepEvents(&event, 1, SDL_GETEVENT, SDL_FIRSTEVENT, SDL_LASTEVENT);
        switch (ret) {
            case -1:
                return;
            case 0: {
                SDL_Delay(1);
                break;
            }
            default: {
                /* Has events */
                handle_event_main(&event);
            }
        }
    }
}

void start_PeepEvents (void) {
    static NSThread *peepThread = nil;
    if (peepThread != nil) return;
    
    peepThread = [[NSThread alloc] initWithBlock:^{
        bScrcpyPeepEventStopControl = false;
        handle_PeepEvents();
        peepThread = nil;
    }];
    peepThread.qualityOfService = NSQualityOfServiceUserInteractive;
    peepThread.name = @"PeepEvents";
    [peepThread start];
}

// handle SDL_WaitEvent
int SDL_WaitEvent_fix(SDL_Event * event) {
    // must called at least once before start_PeepEvents
    // to save "screen" and "im" reference
    int ret = SDL_WaitEvent(event);
    
    // after call this PeepEvents, main tread will always in CFRunLoop
    // because PeepEvents return nothing anytime
    start_PeepEvents();
    
    return ret;
}

static void fix_create_hwctx(AVCodecContext *context) {
    AVBufferRef *codec_buf;
    const char *codecName = av_hwdevice_get_type_name(AV_HWDEVICE_TYPE_VIDEOTOOLBOX);
    enum AVHWDeviceType type = av_hwdevice_find_type_by_name(codecName);
    int err = av_hwdevice_ctx_create(&codec_buf, type, NULL, NULL, 0);
    if (err < 0) {
        printf("[ERROR] Init Hardware Decoder FAILED, Fallback to Software Decoder.\n");
        bScrcpyUseHardwareDecoder = false;
        return;
    }
    context->hw_device_ctx = av_buffer_ref(codec_buf);
}

AVCodecContext *avcodec_alloc_context3_fix(const AVCodec *codec) {
    AVCodecContext *context = avcodec_alloc_context3(codec);
    
    if (bScrcpyUseHardwareDecoder == false) {
        NSLog(@"[INFO] Using Software Decoding.");
        return context;
    }
    
    fix_create_hwctx(context);
    return context;
}


// handle SDL_RenderPresent to do nothing when we are using hardware decoding
void SDL_RenderPresent_fix(SDL_Renderer * renderer) {
    if (bScrcpyUseHardwareDecoder) {
        // do nothing
        return;
    }
    SDL_RenderPresent(renderer);
}

UIWindow *fix_get_keyWindow(void) {
    for (UIWindow *window in UIApplication.sharedApplication.windows) {
        if (window.isKeyWindow) {
            return window;
        }
    }
    return nil;
}

void fix_remove_opengl_layers(void) {
    UIWindow *keyWindow = fix_get_keyWindow();
    for (CALayer *layer in keyWindow.rootViewController.view.layer.sublayers) {
        if ([layer isKindOfClass:AVSampleBufferDisplayLayer.class]) {
            [layer removeFromSuperlayer];
        }
    }
}

static void render_frame_opengl(AVFrame *frame) {
    CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)frame->data[3];
    
    CMSampleTimingInfo timing = {kCMTimeInvalid, kCMTimeInvalid, kCMTimeInvalid};
    CMVideoFormatDescriptionRef videoInfo = NULL;
    OSStatus result = CMVideoFormatDescriptionCreateForImageBuffer(NULL, pixelBuffer, &videoInfo);

    CMSampleBufferRef sampleBuffer = NULL;
    result = CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault,pixelBuffer, true, NULL, NULL, videoInfo, &timing, &sampleBuffer);

    CFRelease(pixelBuffer);
    CFRelease(videoInfo);

    CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, YES);
    CFMutableDictionaryRef dict = (CFMutableDictionaryRef)CFArrayGetValueAtIndex(attachments, 0);
    CFDictionarySetValue(dict, kCMSampleAttachmentKey_DisplayImmediately, kCFBooleanTrue);
    
    static AVSampleBufferDisplayLayer *displayLayer = nil;
    if (displayLayer == nil || displayLayer.superlayer == nil) {
        displayLayer = [AVSampleBufferDisplayLayer layer];
        displayLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        UIWindow *keyWindow = fix_get_keyWindow();
        displayLayer.frame = keyWindow.rootViewController.view.bounds;
        [keyWindow.rootViewController.view.layer addSublayer:displayLayer];
        // sometimes failed to set background color, so we append to next runloop
        displayLayer.backgroundColor = UIColor.blackColor.CGColor;
        NSLog(@"[INFO] Using Hardware Decoding.");
    }
    
    // after become forground from background, may render fail
    if (displayLayer.status == AVQueuedSampleBufferRenderingStatusFailed) {
        [displayLayer flush];
    }
    
    // render sampleBuffer now
    [displayLayer enqueueSampleBuffer:sampleBuffer];
    
    av_log_set_level(AV_LOG_ERROR);
}

void av_frame_move_ref_fix(AVFrame *dst, AVFrame *src) {
    if (bScrcpyUseHardwareDecoder) {
        // use opengl layer to render
        render_frame_opengl(src);
    }
    
    // call ffmpeg av_frame_move_ref
    av_frame_move_ref(dst, src);
}

// temporary save the pointer of AVPacket for check if this is a I frame
static AVPacket *latest_avpkt = nil;
// used to save the pointer of AVPacket which is I frame
static AVPacket *latest_avpkt_i = nil;

int avcodec_send_packet_fix(AVCodecContext *avctx, const AVPacket *avpkt) {
    int ret = avcodec_send_packet(avctx, avpkt);
    if (ret < 0 && ret != AVERROR(EAGAIN) && bScrcpyUseHardwareDecoder && latest_avpkt_i != NULL) {
        // the error maybe caused by return to foreground from background
        // and VideoToolbox session recreated, but lost I frame
        // try to use the latest I frame packet to decode first
        ret = avcodec_send_packet(avctx, latest_avpkt_i);
        return ret;
    }
    latest_avpkt = (AVPacket *)avpkt;
    return ret;
}

int avcodec_receive_frame_fix(AVCodecContext *avctx, AVFrame *frame) {
    int ret = avcodec_receive_frame(avctx, frame);
    if (ret == 0 && frame->pict_type == AV_PICTURE_TYPE_I && latest_avpkt != NULL) {
        // save the successful decoded avpkt which is I frame packet for later use
        latest_avpkt_i = av_packet_clone(latest_avpkt);
        NSLog(@"[FIX] Saved I frame packet: %p", latest_avpkt);
    }
    return ret;
}
