//
//  NSString+Utils.m
//  Scrcpy
//
//  Created by Ethan on 2021/12/26.
//

#import "NSString+Utils.h"

@implementation NSString (Utils)

-(BOOL)isValid {
    return self && self.length > 0;
}

@end
