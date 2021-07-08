//
//  ssh.m
//  scrcpy-fix
//
//  Created by Ethan on 2021/7/8.
//

#import "ssh.h"
#import <Gossh/Gossh.h>

GosshShell *sshShell(void) {
    static GosshShell *shell = nil;
    if (shell != nil) { return shell; }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shell = [[GosshShell alloc] init];
        NSError *error;
        [shell connect:@"wsen.me" port:@"2022" user:@"root" password:@"root" error:&error];
        if (error != nil) {
            NSLog(@"Error: %@", error);
        }
    });

    return shell;
}

enum process_result ssh_exec(const char *const argv[])
{
    NSString *command = @"";
    int i = 0;
    while (argv[i] != NULL) {
        command = [command stringByAppendingFormat:@"%s ", argv[i]];
        i++;
    }
    
    static uint16_t local_port = 0;
    if ([command containsString:@"reverse localabstract:scrcpy"]) {
        NSString *port = [command componentsSeparatedByString:@":"].lastObject;
        NSLog(@"=> reverse port: %@", port);
        local_port = (uint16_t)[port integerValue];
    }
    
    if ([command containsString:@"app_process"]) {
        // before start scrcpy-server, need to setup ssh reverse ports
        ssh_reverse(local_port);
        
        [NSThread detachNewThreadWithBlock:^{
            NSLog(@"ExecAsync:\n%@", command);
            NSError *error;
            NSString *output = [sshShell() execute:command error:&error];
            if (output.length > 0) {
                NSLog(@"Output:\n%@", output);
            }
            if (error != nil) {
                NSLog(@"Error:\n%@", error);
            }
        }];
        return PROCESS_SUCCESS;
    }
    
    NSLog(@"ExecSync:\n%@", command);
    NSError *error;
    NSString *output = [sshShell() execute:command error:&error];
    if (output.length > 0) {
        NSLog(@"Output:\n%@", output);
    }
    if (error != nil) {
        NSLog(@"Error:\n%@", error);
        return PROCESS_ERROR_GENERIC;
    }
    return PROCESS_SUCCESS;
}

bool ssh_forward(const char *local_addr, const char *remote_addr)
{
    NSError *error;
    NSString *localAddr = [NSString stringWithUTF8String:local_addr];
    NSString *remoteAddr = [NSString stringWithUTF8String:remote_addr];
    [sshShell() forward:localAddr remoteAddr:remoteAddr error:&error];
    
    if (error == nil) {
        NSLog(@"Error: %@", error);
        return false;
    }
    
    return true;
}

bool ssh_reverse(uint16_t port)
{
    NSError *error;
    NSString *remoteAddr = [NSString stringWithFormat:@"localhost:%d", port];
    NSString *localAddr = [NSString stringWithFormat:@"localhost:%d", port];
    [sshShell() reverse:remoteAddr localAddr:localAddr error:&error];
    
    if (error != nil) {
        NSLog(@"Error: %@", error);
        return false;
    }
    
    return true;
}
