//
//  ScrcpyBridge.h
//  Scrcpy
//
//  Created by Ethan on 2021/12/2.
//

#import <Foundation/Foundation.h>

#define SharedNotificationCenter    [NSNotificationCenter defaultCenter]

#define kScrcpyUploadFileSSHCommand @"kScrcpyUploadFileSSHCommand"
#define kScrcpyExecuteSSHCommand    @"kScrcpyExecuteSshCommand"
#define kScrcpyReverseSSHCommand    @"kScrcpyReverseSSHCommand"

struct ScrcpyExecuteContext {
    BOOL    ShowErrors;             // Show errors or not
    
    NSString * _Nullable Command;
    
    NSString * _Nullable Local;     // For upload command
    NSString * _Nullable Remote;    // For upload command
    
    uint16_t ReversePort;           // For reverse command
    
    BOOL    Success;
    NSString * _Nullable Stdout;
    NSString * _Nullable Stderr;
};

static inline NSDictionary * _Nullable UserInfoWith(struct ScrcpyExecuteContext * _Nullable context) {
    return @{ @"context" : [NSValue valueWithPointer:context] };
}

static inline struct ScrcpyExecuteContext * _Nullable GetContextFrom(NSDictionary * _Nullable userInfo) {
    return (struct ScrcpyExecuteContext *)[(NSValue *)userInfo[@"context"] pointerValue];
}

NS_ASSUME_NONNULL_BEGIN

@interface ScrcpyBridge : NSObject
@property (nonatomic, assign)   BOOL running;

-(void)resetContext;
-(void)startWith:(NSArray *)options;
@end

NS_ASSUME_NONNULL_END
