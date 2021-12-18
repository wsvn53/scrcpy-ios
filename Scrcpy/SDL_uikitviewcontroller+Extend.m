//
//  SDL_uikitviewcontroller+Extend.m
//  HomeIndicator
//
//  Created by Ethan on 2021/7/25.
//

#import "SDL_uikitviewcontroller+Extend.h"
@import AVFoundation;

@implementation SDL_uikitviewcontroller (Extend)

- (UIRectEdge)preferredScreenEdgesDeferringSystemGestures {
    return UIRectEdgeBottom;
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    for (CALayer *layer in self.view.layer.sublayers) {
        if ([layer isKindOfClass:[AVSampleBufferDisplayLayer class]]) {
            layer.frame = self.view.bounds;
        }
    }
}

@end
