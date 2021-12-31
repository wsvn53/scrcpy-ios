//
//  ScrcpyBridge.m
//  Scrcpy
//
//  Created by Ethan on 2021/12/2.
//

#import "ScrcpyBridge.h"
#import <Gossh/Gossh.h>
#import <SDL2/SDL.h>
#import "ScrcpyParams.h"
#import "NSError+Alert.h"

int scrcpy_main(int argc, char *argv[]);

@interface ScrcpyBridge ()
@property (nonatomic, strong)   GosshShell  *sshShell;
@end

@implementation ScrcpyBridge

- (instancetype)init
{
    self = [super init];
    if (self) {
        [SharedNotificationCenter addObserver:self selector:@selector(postExecuteSSHCommand:)
                                         name:kScrcpyExecuteSSHCommand object:nil];
        [SharedNotificationCenter addObserver:self selector:@selector(postUploadFileSSHCommand:)
                                         name:kScrcpyUploadFileSSHCommand object:nil];
        [SharedNotificationCenter addObserver:self selector:@selector(postReverseSSHCommand:)
                                         name:kScrcpyReverseSSHCommand object:nil];
        [SharedNotificationCenter addObserver:self selector:@selector(resetContext)
                                         name:kOnScrcpyQuitRequested object:nil];
    }
    return self;
}

-(void)dealloc {
    [SharedNotificationCenter removeObserver:self];
}

-(void)resetContext {
    // Because after SDL proxied didFinishLauch, PumpEvent will set to FASLE
    // So we need to set to TRUE in order to handle UI events
    SDL_iPhoneSetEventPump(SDL_TRUE);
    
    // Flush all events include the not proccessed SERVER_DISCONNECT events
    SDL_FlushEvents(0, 0xFFFF);
    
    // Close ssh session
    if (self.sshShell.connected) {
        [self.sshShell close:nil];
        _sshShell = nil;
    }
}

-(void)startWith:(NSArray *)options {
    self.running = YES;
    
    char *scrcpy_opts[options.count];
    for (NSInteger i = 0; i < options.count; i ++) {
        scrcpy_opts[i] = strdup([options[i] UTF8String]);
    }
    scrcpy_main((int)options.count, scrcpy_opts);
    
    self.running = NO;
}

#pragma mark - SSH

-(BOOL)sshCheckLogin {
    if (self.sshShell.connected) {
        return YES;
    }
    
    NSError *error = nil;
    ScrcpyParams *params = [ScrcpyParams sharedParams];
    [self.sshShell connect:params.sshServer
                      port:params.sshPort
                      user:params.sshUser
                  password:params.sshPassword
                     error:&error];
    
    if (error != nil) {
        [error showAlert];
    }
    
    return self.sshShell.connected;
}

-(void)postExecuteSSHCommand:(NSNotification *)executeNotification {
    // check ssh login first
    if ([self sshCheckLogin] == NO) {
        return;
    }
    
    // get command context
    struct ScrcpyExecuteContext *context = (struct ScrcpyExecuteContext *)GetContextFrom(executeNotification.userInfo);
    
    // assembly adb commands
    GosshShellStatus *ret = [self.sshShell execute:(*context).Command];
    (*context).Stdout = ret.output;
    (*context).Stderr = ret.err.description;
    (*context).Success = (ret.err == nil);
    NSLog(@"RET> [%@] (%@)", (*context).Command, @((*context).Success));
    
    if (ret.err != nil && (*context).ShowErrors) {
        NSString *descStr = [NSString stringWithFormat:@"CMD> %@\nOUTPUT> %@\nERR> %@", (*context).Command, ret.output, ret.err.userInfo[NSLocalizedDescriptionKey]];
        NSError *showErr = [NSError errorWithDomain:ret.err.domain code:ret.err.code userInfo:@{
            NSLocalizedDescriptionKey: descStr,
        }];
        [showErr showAlert];
    }
}

-(void)postUploadFileSSHCommand:(NSNotification *)executeNotification {
    // check ssh login first
    if ([self sshCheckLogin] == NO) {
        return;
    }
    
    // get upload context
    struct ScrcpyExecuteContext *context = (struct ScrcpyExecuteContext *)GetContextFrom(executeNotification.userInfo);
    
    NSError *error = nil;
    (*context).Success = [self.sshShell uploadFile:(*context).Local dst:(*context).Remote error:&error];
    (*context).Stderr = [error description];
    
    NSLog(@"RET> Upload [%@] => [%@] (%@)", (*context).Local, (*context).Remote, (*context).Success?@"YES":@"NO");
    
    if (error != nil && (*context).ShowErrors) {
        [error showAlert];
    }
}

-(void)postReverseSSHCommand:(NSNotification *)reverseNotification {
    // check ssh login first
    if ([self sshCheckLogin] == NO) {
        return;
    }
    
    // get reverse context
    struct ScrcpyExecuteContext *context = (struct ScrcpyExecuteContext *)GetContextFrom(reverseNotification.userInfo);
    
    // force exit other clients first
    // TODO: try to change to adb reverse remove
    NSString *killCmds = @"pgrep -f \"scrcpy[-]server\" && kill `pgrep -f \"scrcpy[-]server\"`";
    GosshShellStatus *status = [self.sshShell execute:killCmds];
    NSString *killedPids = status.output;
    
    // if command returns error, there's no other clients
    // otherwise, we need wait a moment
    if (killedPids.length > 0) {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.5f, NO);
    }
    
    NSString *remoteAddr = [NSString stringWithFormat:@"localhost:%d", (*context).ReversePort];
    NSString *localAddr = [NSString stringWithFormat:@"localhost:%d", (*context).ReversePort];
    
    NSError *error = nil;
    NSInteger retryCount = 5;
    while (--retryCount) {
        BOOL success = [self.sshShell reverse:remoteAddr localAddr:localAddr error:&error];
        if (success == NO && error != nil) {
            NSLog(@"[SSH Reverse]: %@, RetryRemains: %ld", error, retryCount);
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.5f, NO);
            continue;
        }
        
        error = nil;
        (*context).Success = YES;
        break;
    }
    
    if (error != nil && (*context).Success) {
        NSLog(@"Error: %@", error);
        [error showAlert];
    }
}

#pragma mark - Getters/Setters

-(GosshShell *)sshShell {
    _sshShell = _sshShell ? : [[GosshShell alloc] init];
    return _sshShell;
}

@end
