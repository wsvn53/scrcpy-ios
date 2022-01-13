//
//  scrcpy_bridge.c
//  scrcpy-bridge
//
//  Created by Ethan on 2021/12/9.
//

#import "scrcpy_bridge.h"
#import "ScrcpyBridge.h"
#import "NSError+Alert.h"
#import <SDL2/SDL.h>
#import "screen-fix.h"

/**
 * Quit current scrcpy connection
 */
void scrcpy_quit(void) {
    // Call SQL_Quit direct
    SDL_Quit();
    
    // Reset hardware display layer
    display_layer_reset();
    
    // Post notification to close ssh
    [[NSNotificationCenter defaultCenter] postNotificationName:kOnScrcpyQuitRequested object:nil];
}

/**
 * Fix using CFRunLoopRunInMode in SDL to avoid high cpu usage
 */
CFRunLoopRunResult CFRunLoopRunInMode_fix(CFRunLoopMode mode, CFTimeInterval seconds, Boolean returnAfterSourceHandled) {
    return CFRunLoopRunInMode(mode, 0.006, NO);
}

/**
 * Store Running Threads
 */

static NSMutableArray *sshRunningThreads = nil;
static inline NSMutableArray *GetSSHRunningThreads() {
    if (sshRunningThreads == nil) {
        sshRunningThreads = [[NSMutableArray alloc] init];
    }
    return sshRunningThreads;
}

/**
 * Wait thread exit
 */
void
scrcpy_thread_wait(pid_t pid) {
    NSString *threadName = [NSString stringWithFormat:@"%d", pid];
    NSMutableArray *removingThreads = [NSMutableArray new];
    NSMutableArray *runningThreads = GetSSHRunningThreads();
    
    while (YES) {
        BOOL running = NO;
        for (NSThread *thread in runningThreads) {
            // check thread status to remove later
            if (thread.isFinished || thread.isCancelled) {
                [removingThreads addObject:thread];
            }
            
            if ([thread.name isEqualToString:threadName]) {
                running = YES;
                break;
            }
        }
        
        // remove exited threads
        if (removingThreads.count > 0) {
            [runningThreads removeObjectsInArray:removingThreads];
            [removingThreads removeAllObjects];
        }
        
        // thread exited
        if (running == NO) {
            return;
        }
        
        // otherwise continue to check
        usleep(100000);
    }
}

/**
 * Exit all running threads
 */
void scrcpy_thread_exit(pid_t pid) {
    NSString *threadName = [NSString stringWithFormat:@"%d", pid];
    NSMutableArray *runningThreads = GetSSHRunningThreads();
    for (NSThread *thread in runningThreads) {
        if ([thread.name isEqualToString:threadName]) {
            [thread cancel];
        }
    }
}

/**
 * Execute ssh command in background thread
 */
uint16_t scrcpy_ssh_execute_bg(const char *const ssh_cmd[], size_t len) {
    __block NSMutableArray *cmdStrs = [[NSMutableArray alloc] init];
    for(int i = 0; i < len; i++) {
        [cmdStrs addObject:[NSString stringWithUTF8String:ssh_cmd[i]]];
    }
    
    NSThread *execThread = [[NSThread alloc] initWithBlock:^{
        const char *cmds[len];
        for (int i = 0; i < len; i++) {
            cmds[i] = [cmdStrs[i] UTF8String];
        }
        scrcpy_ssh_execute(cmds, len, true);
    }];
    
    // save to running thread for later check
    [GetSSHRunningThreads() addObject:execThread];
    
    NSString *threadCmd = @"";
    for (int i = 0; i < len; i++) {
        threadCmd = [threadCmd stringByAppendingFormat:@" %s", ssh_cmd[i]];
    }
    uint16_t fake_pid = threadCmd.hash % 1000000;
    execThread.name = [NSString stringWithFormat:@"%d", fake_pid];
    [execThread start];
    
    // Wait for ssh_cmd array was used
//    CFRunLoopRunInMode(kCFRunLoopCommonModes, 0.1, NO);
    
    // fake pid
    return fake_pid;
}

const char *scrcpy_ssh_execute(const char *const ssh_cmd[], size_t len, bool silent) {
    struct ScrcpyExecuteContext context;
    NSMutableArray *sshCmdFields = [NSMutableArray new];
    for (int i = 0; i < len; i++) {
        [sshCmdFields addObject:[NSString stringWithFormat:@"%s", ssh_cmd[i]]];
    }
    context.Command = [sshCmdFields componentsJoinedByString:@" "];
    context.ShowErrors = !silent;
    NSLog(@"CMD> %@", context.Command);
    [SharedNotificationCenter postNotificationName:kScrcpyExecuteSSHCommand object:nil
                                          userInfo:UserInfoWith(&context)];
    
    if (context.Success == NO) {
        return NULL;
    }
    
    NSString *output = [context.Stdout stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    return [output cStringUsingEncoding:NSUTF8StringEncoding];
}

bool scrcpy_ssh_upload(const char *local, const char *remote) {
    struct ScrcpyExecuteContext context;
    
    context.ShowErrors = YES;
    context.Local = [[NSBundle mainBundle] pathForResource:[NSString stringWithUTF8String:local] ofType:@""];
    context.Remote = [NSString stringWithUTF8String:remote];
    [SharedNotificationCenter postNotificationName:kScrcpyUploadFileSSHCommand object:nil
                                          userInfo:UserInfoWith(&context)];
    return context.Success;
}

bool scrcpy_ssh_reverse(uint16_t port) {
    // no reverse port, mabye forward mode
    if (port == 0) return false;
    
    struct ScrcpyExecuteContext context;
    context.ShowErrors = YES;
    context.ReverseTunnel = YES;
    context.TunnelPort = port;
    [SharedNotificationCenter postNotificationName:kScrcpyTunnelSSHCommand object:nil
                                          userInfo:UserInfoWith(&context)];
    return context.Success;
}

bool scrcpy_ssh_forward(uint16_t port) {
    // no reverse port, mabye forward mode
    if (port == 0) return false;
    
    struct ScrcpyExecuteContext context;
    context.ShowErrors = YES;
    context.ReverseTunnel = NO;
    context.TunnelPort = port;
    [SharedNotificationCenter postNotificationName:kScrcpyTunnelSSHCommand object:nil
                                          userInfo:UserInfoWith(&context)];
    return context.Success;
}
