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

UIKIT_EXTERN UIImage * __nullable UIColorAsImage(UIColor * __nonnull color, CGSize size) {
    
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, [UIScreen mainScreen].scale);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context,color.CGColor);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}
