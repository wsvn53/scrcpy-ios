//
//  utils.m
//  scrcpy-fix
//
//  Created by Ethan on 2021/7/8.
//

#import "utils.h"
#import <UIKit/UIKit.h>

float screen_scale(void) {
    if ([UIScreen.mainScreen respondsToSelector:@selector(nativeScale)]) {
        return UIScreen.mainScreen.nativeScale;
    }
    return UIScreen.mainScreen.scale;
}
