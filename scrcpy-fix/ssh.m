//
//  ssh.m
//  scrcpy-fix
//
//  Created by Ethan on 2021/7/8.
//

#import "ssh.h"
#import <Gossh/Gossh.h>
#import "NSError+Alert.h"
#import "ExecStatus.h"

process_t adb_reverse_remove(const char *serial, const char *device_socket_name);

@implementation SSHParams

+(SSHParams *)sharedParams {
    static SSHParams *sshParams = nil;
    if (sshParams == nil) {
        sshParams = [[SSHParams alloc] init];
        [sshParams loadDefaults];
    }
    return sshParams;
}

+(void)setParamsWithServer:(NSString *)server
                      port:(NSString *)port
                      user:(NSString *)user
                  password:(NSString *)password {
    [self sharedParams].sshServer = server;
    [self sharedParams].sshPort   = port;
    [self sharedParams].sshUser   = user;
    [self sharedParams].sshPassword = password;
    
    [[self sharedParams] saveDefaults];
}

- (void)saveDefaults {
    [[NSUserDefaults standardUserDefaults] setValue:self.sshServer forKey:@"ssh_server"];
    [[NSUserDefaults standardUserDefaults] setValue:self.sshPort forKey:@"ssh_port"];
    [[NSUserDefaults standardUserDefaults] setValue:self.sshUser forKey:@"ssh_user"];
    [[NSUserDefaults standardUserDefaults] setValue:self.sshPassword forKey:@"ssh_password"];
}

- (void)loadDefaults {
    self.sshServer = [[NSUserDefaults standardUserDefaults] valueForKey:@"ssh_server"];
    self.sshPort = [[NSUserDefaults standardUserDefaults] valueForKey:@"ssh_port"];
    if (self.sshPort == nil || self.sshPort.length == 0) {
        self.sshPort = @"22";
    }
    self.sshUser = [[NSUserDefaults standardUserDefaults] valueForKey:@"ssh_user"];
    self.sshPassword = [[NSUserDefaults standardUserDefaults] valueForKey:@"ssh_password"];
}

- (NSString *)scrcpyServer {
    if (_scrcpyServer.length > 0) {
        return _scrcpyServer;
    }
    _scrcpyServer = @"/usr/local/scrcpy/scrcpy-server";
    return _scrcpyServer;
}

@end

GosshShell *sshShell(void) {
    static GosshShell *shell = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shell = [[GosshShell alloc] init];
    });
    
    if (shell.connected) {
        return shell;
    }
    
    // reset error status
    [[ExecStatus sharedStatus] resetStatus];
    
    NSError *error;
    SSHParams *sshParams = [SSHParams sharedParams];
    [shell connect:sshParams.sshServer
              port:sshParams.sshPort
              user:sshParams.sshUser
          password:sshParams.sshPassword
             error:&error];
    if (error != nil) {
        NSLog(@"Error: %@", error);
        [error showAlert];
    }
    return shell;
}

bool ssh_upload_scrcpyserver(void) {
    NSString *scrcpyServer = [[NSBundle mainBundle] pathForResource:@"scrcpy-server" ofType:@""];
    NSError *error = nil;
    NSString *scrcpyDst = [SSHParams sharedParams].scrcpyServer;
    BOOL success = [sshShell() uploadFile:scrcpyServer dst:scrcpyDst error:&error];
    if (success == NO && error != nil) {
        [error showAlert];
        return false;
    }
    NSLog(@"Upload scrcpy-server: %@", scrcpyDst);
    return true;
}

enum process_result ssh_exec_command(NSString *command) {
    NSLog(@"Exec:\n%@", command);
    NSError *error;
    NSString *output = [sshShell() execute:command error:&error];
    if (output != nil && output.length > 0) {
        NSLog(@"Output:\n%@", output);
    }
    if (error != nil) {
        NSLog(@"Error:\n%@", error);
        [error showAlert];
        [[ExecStatus sharedStatus] setError:error forCommand:command];
        return PROCESS_ERROR_GENERIC;
    }
    return PROCESS_SUCCESS;
}

enum process_result ssh_exec(const char *const argv[])
{
    NSString *command = @"";
    int i = 0;
    while (argv[i] != NULL) {
        command = [command stringByAppendingFormat:@"%s ", argv[i]];
        i++;
    }
    
    // upload scrcpy-server before adb push
    if ([command containsString:@"push"]) {
        bool result = ssh_upload_scrcpyserver();
        if (result == false) {
            return PROCESS_ERROR_MISSING_BINARY;
        }
    }
    
    // save port number for ssh reverse use
    static uint16_t local_port = 0;
    if ([command containsString:@"reverse localabstract:scrcpy"]) {
        NSString *port = [command componentsSeparatedByString:@":"].lastObject;
        NSLog(@"=> reverse port: %@", port);
        local_port = (uint16_t)[port integerValue];
    }
    
    // reverse port via ssh before run scrcpy-server
    if ([command containsString:@"app_process"]) {
        // need to setup ssh reverse ports before start scrcpy-server
        ssh_reverse(local_port);
        
        [NSThread detachNewThreadWithBlock:^{
            ssh_exec_command(command);
            
            // force exit in order to allow other connect
            dispatch_sync(dispatch_get_main_queue(), ^{ exit(0); });
        }];
        
        return PROCESS_SUCCESS;
    }
    
    return ssh_exec_command(command);
}

bool ssh_reverse(uint16_t port)
{
    NSError *error = nil;
    
    // force exit other clients first
    NSString *killedPids = [sshShell() execute:@"pgrep -f \"scrcpy[-]server\" && kill `pgrep -f \"scrcpy[-]server\"`" error:&error];
    
    // if command returns error, there's no other clients
    // otherwise, we need wait a moment
    if (killedPids.length > 0) {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.5f, NO);
    }
    
    NSString *remoteAddr = [NSString stringWithFormat:@"localhost:%d", port];
    NSString *localAddr = [NSString stringWithFormat:@"localhost:%d", port];
    
    NSInteger retryCount = 5;
    while (--retryCount) {
        BOOL success = [sshShell() reverse:remoteAddr localAddr:localAddr error:&error];
        if (success == NO && error != nil) {
            NSLog(@"[adb reverse]: %@, count: %ld", error, retryCount);
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.5f, NO);
            continue;
        }
        error = nil;
        break;
    }
    
    if (error != nil) {
        NSLog(@"Error: %@", error);
        return false;
    }

    return true;
}

