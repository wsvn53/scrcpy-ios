//
//  ExecStatus.h
//  scrcpy-fix
//
//  Created by Ethan on 2021/7/13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ExecStatus : NSObject

+ (instancetype)sharedStatus;
- (BOOL)checkSuccess:(const char *)command;
- (void)setError:(NSError *)err forCommand:(NSString *)command;
- (void)resetStatus;

@end

NS_ASSUME_NONNULL_END
