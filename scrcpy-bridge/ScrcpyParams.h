//
//  ScrcpyParams.h
//  ScrcpyParams
//
//  Created by Ethan on 2021/8/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ScrcpyParams;
typedef void (^ScrcpyBindBlock)(void);
void ScrcpyParamsBind(ScrcpyBindBlock showBlock, ScrcpyBindBlock storeBlock);
void ScrcpyParamsSave(NSString *key, id value);
id ScrcpyParamsLoad(NSString *key, id defaultValue);

#define ScrcpyParams_bind(targetValue, paramProp, paramKey, defaultValue)   \
ScrcpyParamsBind(^{                                                         \
    paramProp = ScrcpyParamsLoad(paramKey, defaultValue);                   \
    targetValue = paramProp;                                                \
}, ^{                                                                       \
    paramProp = targetValue;                                                \
    ScrcpyParamsSave(paramKey, paramProp);                                  \
})

@interface ScrcpyParams : NSObject

@property (nonatomic, copy)     NSString    *sshServer;
@property (nonatomic, copy)     NSString    *sshPort;
@property (nonatomic, copy)     NSString    *sshUser;
@property (nonatomic, copy)     NSString    *sshPassword;

@property (nonatomic, copy)     NSString    *adbSerial;
@property (nonatomic, copy)     NSString    *scrcpyServer;
@property (nonatomic, copy)     NSString    *maxSize;
@property (nonatomic, copy)     NSString    *bitRate;
@property (nonatomic, copy)     NSNumber    *screenOff;

@property (nonatomic, copy)     NSString    *coreVersion;
@property (nonatomic, copy)     NSString    *appVersion;

@property (nonatomic, copy, nullable)     NSURL       *autoConnectURL;

+(ScrcpyParams *)sharedParams;
-(void)bindParam:(ScrcpyBindBlock)showBlock store:(ScrcpyBindBlock)storeBlock;
- (void)saveDefaults;
- (void)loadDefaults;

@end

NS_ASSUME_NONNULL_END
