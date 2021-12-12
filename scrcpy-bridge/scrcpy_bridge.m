//
//  scrcpy_bridge.c
//  scrcpy-bridge
//
//  Created by Ethan on 2021/12/9.
//

#import "scrcpy_bridge.h"
#import "ScrcpyBridge.h"
#import "NSError+Alert.h"

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
            if ([thread.name isEqualToString:threadName]) {
                running = YES;
                break;
            }
            
            if (thread.isFinished || thread.isCancelled) {
                [removingThreads addObject:thread];
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
        scrcpy_ssh_execute(cmds, len);
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
    CFRunLoopRunInMode(kCFRunLoopCommonModes, 0.1, NO);
    
    // fake pid
    return fake_pid;
}

const char *scrcpy_ssh_execute(const char *const ssh_cmd[], size_t len) {
    struct ScrcpyExecuteContext context;
    NSMutableArray *sshCmdFields = [NSMutableArray new];
    for (int i = 0; i < len; i++) {
        [sshCmdFields addObject:[NSString stringWithFormat:@"%s", ssh_cmd[i]]];
    }
    context.Command = [sshCmdFields componentsJoinedByString:@" "];
    context.ShowErrors = YES;
    NSLog(@"CMD> %@", context.Command);
    [SharedNotificationCenter postNotificationName:kScrcpyExecuteSSHCommand object:nil
                                          userInfo:UserInfoWith(&context)];
    
    if (context.Success == NO) {
        return NULL;
    }
    
    NSString *serialNo = [context.Stdout stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    return [serialNo cStringUsingEncoding:NSUTF8StringEncoding];
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
    context.ReversePort = port;
    [SharedNotificationCenter postNotificationName:kScrcpyReverseSSHCommand object:nil
                                          userInfo:UserInfoWith(&context)];

    return context.Success;
}
