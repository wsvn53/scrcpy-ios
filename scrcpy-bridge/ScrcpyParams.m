//
//  ScrcpyParams.m
//  ScrcpyParams
//
//  Created by Ethan on 2021/8/14.
//

#import "ScrcpyParams.h"
#import "config.h"
#import <objc/runtime.h>
#import "NSString+Utils.h"

void ScrcpyParamsSave(NSString *key, id value) {
    [[NSUserDefaults standardUserDefaults] setValue:value forKey:key];
}

id ScrcpyParamsLoad(NSString *key, id defaultValue) {
    id value = [[NSUserDefaults standardUserDefaults] stringForKey:key];
    value = value ? : defaultValue;
    return value;
}

void ScrcpyParamsBind(ScrcpyBindBlock showBlock, ScrcpyBindBlock storeBlock) {
    [[ScrcpyParams sharedParams] bindParam:showBlock store:storeBlock];
}

@interface ScrcpyParams ()
@property (nonatomic, strong)   NSMutableArray  *showBlocks;
@property (nonatomic, strong)   NSMutableArray  *storeBlocks;
@end

@implementation ScrcpyParams

+(ScrcpyParams *)sharedParams {
    static ScrcpyParams *sshParams = nil;
    if (sshParams == nil) {
        sshParams = [[ScrcpyParams alloc] init];
        [sshParams loadDefaults];
    }
    return sshParams;
}

- (void)bindParam:(ScrcpyBindBlock)showBlock store:(ScrcpyBindBlock)storeBlock {
    self.showBlocks = self.showBlocks ? : [NSMutableArray new];
    self.storeBlocks = self.storeBlocks ? : [NSMutableArray new];
    [self.showBlocks addObject:showBlock];
    [self.storeBlocks addObject:storeBlock];
}

- (void)saveDefaults {
    for (ScrcpyBindBlock block in self.storeBlocks) {
        block();
    }
}

- (void)loadDefaults {
    for (ScrcpyBindBlock block in self.showBlocks) {
        block();
    }
}

- (NSString *)scrcpyServer {
    if (_scrcpyServer.isValid) {
        return _scrcpyServer;
    }
    NSString *prefixDir = [NSString stringWithUTF8String:PREFIX];
    _scrcpyServer = [prefixDir stringByAppendingString:@"/share/scrcpy/scrcpy-server"];
    return _scrcpyServer;
}

- (NSString *)coreVersion {
    if (_coreVersion.isValid) {
        return _coreVersion;
    }
    _coreVersion = [NSString stringWithUTF8String:SCRCPY_VERSION];
    return _coreVersion;
}

- (NSString *)appVersion {
    if (_appVersion.isValid) {
        return _appVersion;
    }
    NSString *shortVersion = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *buildVersion = [NSBundle.mainBundle objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
    _appVersion = [NSString stringWithFormat:@"v%@+%@", shortVersion, buildVersion];
    return _appVersion;
}

@end
