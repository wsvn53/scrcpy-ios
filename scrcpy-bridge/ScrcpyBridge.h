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
#define kScrcpyTunnelSSHCommand    @"kScrcpyTunnelSSHCommand"
#define kScrcpyForwardSSHCommand    @"kScrcpyForwardSSHCommand"
#define kOnScrcpyQuitRequested      @"kOnScrcpyQuitRequested"

struct ScrcpyExecuteContext {
    BOOL    ShowErrors;             // Show errors or not
    
    NSString * _Nullable Command;
    
    NSString * _Nullable Local;     // For upload command
    NSString * _Nullable Remote;    // For upload command
    
    BOOL     ReverseTunnel;           // For reverse tunnel command
    uint16_t TunnelPort;           // For forward tunnel command
    
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

-(void)appendError:(NSError *)error;
-(void)showErrors;
-(void)clearErrors;

@end

NS_ASSUME_NONNULL_END
