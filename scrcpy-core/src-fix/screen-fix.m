//
//  screen-fix.m
//  scrcpy-core
//
//  Created by Ethan on 2021/12/10.
//

#import <SDL2/SDL.h>
#import <SDL2/SDL_render.h>

/**
 * Handle SDL_UpdateYUVTexture to disable render texture, in order to prevent show green background
 */
int SDLCALL SDL_RenderCopy_fix(SDL_Renderer * renderer,
                           SDL_Texture * texture,
                           const SDL_Rect * srcrect,
                           const SDL_Rect * dstrect) {
    return 0;
}

#define screen_init(...)   screen_init_orig(__VA_ARGS__)
#define screen_handle_event(...)   screen_handle_event_orig(__VA_ARGS__)
#define SDL_RenderCopy(...)        SDL_RenderCopy_fix(__VA_ARGS__)

#include "screen.c"

#undef screen_init
#undef screen_handle_event
#undef SDL_RenderCopy

#import "screen-fix.h"

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@import CoreMedia;
@import CoreVideo;
@import VideoToolbox;
@import AVFoundation;

static inline UIWindow *getKeyWindow(void) {
    for (UIWindow *window in UIApplication.sharedApplication.windows) {
        if (window.isKeyWindow) {
            return window;
        }
    }
    return nil;
}

static inline void OpenGL_RenderFrame(AVFrame *frame) {
    CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)frame->data[3];
    if (pixelBuffer == NULL) {
        return;
    }
    
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
        UIWindow *keyWindow = getKeyWindow();
        displayLayer.frame = keyWindow.rootViewController.view.bounds;
        [keyWindow.rootViewController.view.layer addSublayer:displayLayer];
        keyWindow.rootViewController.view.backgroundColor = UIColor.blackColor;
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

bool screen_handle_event(struct screen *screen, SDL_Event *event) {
    if (event->type == EVENT_NEW_FRAME) {
        OpenGL_RenderFrame(screen->frame);
    }
    
    return screen_handle_event_orig(screen, event);
}

float screen_scale(void) {
    if ([UIScreen.mainScreen respondsToSelector:@selector(nativeScale)]) {
        return UIScreen.mainScreen.nativeScale;
    }
    return UIScreen.mainScreen.scale;
}

bool
screen_init(struct screen *screen, const struct screen_params *params) {
    bool ret = screen_init_orig(screen, params);

    // Set renderer scale
    SDL_RenderSetScale(screen->renderer, screen_scale(), screen_scale());

    return ret;
}
