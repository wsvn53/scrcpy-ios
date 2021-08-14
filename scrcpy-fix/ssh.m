//
//  ssh.m
//  scrcpy-fix
//
//  Created by Ethan on 2021/7/8.
//

#import "ssh.h"
#import <Gossh/Gossh.h>
#import "NSError+Alert.h"
#import "config.h"
#import "fix.h"
#import <SDL2/SDL.h>

process_t adb_reverse_remove(const char *serial, const char *device_socket_name);

GosshShell *sshShell(void) {
    static GosshShell *shell = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shell = [[GosshShell alloc] init];
    });
    
    if (shell.connected) {
        return shell;
    }
    
    NSError *error;
    ScrcpyParams *sshParams = [ScrcpyParams sharedParams];
    [shell connect:sshParams.sshServer port:sshParams.sshPort user:sshParams.sshUser password:sshParams.sshPassword error:&error];
    if (error != nil) {
        NSLog(@"Error: %@", error);
        [error showAlert];
        return nil;
    }
    return shell;
}

void ssh_close(void) {
    NSError *error = nil;
    [sshShell() close:&error];
    
    if (error != nil) {
        [error showAlert];
    }
}

void scrcpy_shutdown(void) {
    // force exit in order to allow other connect
    ssh_close();
    process_wait_stop();

    // quit SQL & remove render layers
    dispatch_async(dispatch_get_main_queue(), ^{
        fix_remove_opengl_layers();
        SDL_Quit();
    });
}

NSError *errorAppendDesc(NSError *error, NSString *desc) {
    NSString *newDesc = error.userInfo ? error.userInfo[NSLocalizedDescriptionKey] : @"";
    newDesc = [newDesc stringByAppendingFormat:@"\n\n%@", desc];
    return [NSError errorWithDomain:error.domain?:@"Scrcpy" code:error.code userInfo:@{
        NSLocalizedDescriptionKey : newDesc,
    }];
}

bool ssh_upload_scrcpyserver(void) {
    NSString *scrcpyServer = [[NSBundle mainBundle] pathForResource:@"scrcpy-server" ofType:@""];
    NSError *error = nil;
    NSString *scrcpyDst = [ScrcpyParams sharedParams].scrcpyServer;
    BOOL success = [sshShell() uploadFile:scrcpyServer dst:scrcpyDst error:&error];
    if (success == NO || error != nil) {
        NSError *newErr = errorAppendDesc(error, @"Please check the PERMISSION of remote scrcpy-server path.");
        [newErr showAlert];
        return false;
    }
    NSLog(@"Uploaded: %@", scrcpyDst);
    return true;
}

enum process_result ssh_exec_command(NSString *command) {
    NSLog(@"Exec:\n%@", command);
    GosshShellStatus *status = [sshShell() execute:command];
    if (status.output.length > 0) {
        NSLog(@"Output:\n%@", status.output);
    }
    if (status.err != nil) {
        NSLog(@"Error:\n%@", status.err);
        NSError *newErr = errorAppendDesc(status.err, status.command);
        newErr = errorAppendDesc(newErr, status.output);
        [[ExecStatus sharedStatus] setError:newErr forCommand:command];
        [newErr showAlert];
        
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
    static NSString *adb_push_command = nil;
    if ([command containsString:@"push"]) {
        adb_push_command = [command copy];
        bool result = ssh_upload_scrcpyserver();
        if (result == false) {
            return PROCESS_ERROR_MISSING_BINARY;
        }
    }
    
    // save port number for ssh reverse use
    static uint16_t reverse_port = 0;
    if ([command containsString:@"reverse localabstract:scrcpy"]) {
        NSString *port = [command componentsSeparatedByString:@":"].lastObject;
        NSLog(@"=> reverse port: %@", port);
        reverse_port = (uint16_t)[port integerValue];
    }
    
    // save port number for ssh forward use
    static uint16_t forward_port = 0;
    if ([command containsString:@"forward tcp"]) {
        NSString *port = [command componentsSeparatedByString:@"tcp:"].lastObject;
        port = [port componentsSeparatedByString:@" "].firstObject;
        NSLog(@"=> forward port: %@", port);
        forward_port = (uint16_t)[port integerValue];
        
        // setup ssh forward ports before start scrcpy-server
        ssh_forward(forward_port);
    }
    
    // reverse port via ssh before run scrcpy-server
    if ([command containsString:@"app_process"]) {
        // need to setup ssh reverse ports before start scrcpy-server
        ssh_reverse(reverse_port);
        
        [NSThread detachNewThreadWithBlock:^{
            ssh_exec_command(command);
            scrcpy_shutdown();
        }];
        
        return PROCESS_SUCCESS;
    }
    
    return ssh_exec_command(command);
}

bool ssh_forward(uint16_t port) {
    // ne forward port, maybe reverse mode
    if (port == 0) return false;
    
    // force exit other clients first
    NSString *killCmds = @"pgrep -f \"scrcpy[-]server\" && kill `pgrep -f \"scrcpy[-]server\"`";
    GosshShellStatus *status = [sshShell() execute:killCmds];
    NSString *killedPids = status.output;
    
    // if command returns error, there's no other clients
    // otherwise, we need wait a moment
    if (killedPids.length > 0) {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.5f, NO);
    }
    
    NSString *remoteAddr = [NSString stringWithFormat:@"localhost:%d", port];
    NSString *localAddr = [NSString stringWithFormat:@"localhost:%d", port];
    
    NSError *error = nil;
    NSInteger retryCount = 5;
    while (--retryCount) {
        BOOL success = [sshShell() forward:localAddr remoteAddr:remoteAddr error:&error];
        if (success == NO && error != nil) {
            NSLog(@"[ssh forward]: %@, count: %ld", error, retryCount);
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.5f, NO);
            continue;
        }
        error = nil;
        break;
    }
    
    if (error != nil) {
        NSLog(@"Error: %@", error);
        [error showAlert];
        scrcpy_shutdown();
        return false;
    }
    
    return true;
}

bool ssh_reverse(uint16_t port)
{
    // no reverse port, mabye forward mode
    if (port == 0) return false;
    
    // force exit other clients first
    NSString *killCmds = @"pgrep -f \"scrcpy[-]server\" && kill `pgrep -f \"scrcpy[-]server\"`";
    GosshShellStatus *status = [sshShell() execute:killCmds];
    NSString *killedPids = status.output;
    
    // if command returns error, there's no other clients
    // otherwise, we need wait a moment
    if (killedPids.length > 0) {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.5f, NO);
    }
    
    NSString *remoteAddr = [NSString stringWithFormat:@"localhost:%d", port];
    NSString *localAddr = [NSString stringWithFormat:@"localhost:%d", port];
    
    NSError *error = nil;
    NSInteger retryCount = 5;
    while (--retryCount) {
        BOOL success = [sshShell() reverse:remoteAddr localAddr:localAddr error:&error];
        if (success == NO && error != nil) {
            NSLog(@"[ssh reverse]: %@, count: %ld", error, retryCount);
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.5f, NO);
            continue;
        }
        error = nil;
        break;
    }
    
    if (error != nil) {
        NSLog(@"Error: %@", error);
        [error showAlert];
        scrcpy_shutdown();
        return false;
    }

    return true;
}

