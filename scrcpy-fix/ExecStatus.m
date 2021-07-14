//
//  ExecStatus.m
//  scrcpy-fix
//
//  Created by Ethan on 2021/7/13.
//

#import "ExecStatus.h"

@interface ExecStatus ()

@property (nonatomic, strong)   NSMutableDictionary *execErrors;

@end

@implementation ExecStatus

+ (instancetype)sharedStatus {
    static ExecStatus *status = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (status == nil) {
            status = [[ExecStatus alloc] init];
        }
    });
    return status;
}

- (instancetype)init {
    self = [super init];
    self.execErrors = [[NSMutableDictionary alloc] init];
    return self;
}

- (BOOL)checkSuccess:(const char *)command {
    for (NSString *commandExeced in self.execErrors.allKeys) {
        if ([commandExeced hasPrefix:[NSString stringWithFormat:@"%s", command]]) {
            return NO;
        }
    }
    return YES;
}

- (void)setError:(NSError *)err forCommand:(NSString *)command {
    [self.execErrors setValue:err forKey:command];
}

- (void)resetStatus {
    self.execErrors = [[NSMutableDictionary alloc] init];
}

@end
