//
//  ssh.h
//  scrcpy-fix
//
//  Created by Ethan on 2021/7/8.
//

#import <Foundation/Foundation.h>
#import <util/process.h>
#import "ExecStatus.h"

enum process_result ssh_exec(const char *const argv[]);
bool ssh_forward(const char *local_addr, const char *remote_addr);
bool ssh_reverse(uint16_t port);

@interface ScrcpyParams : NSObject
@property (nonatomic, copy)     NSString    *sshServer;
@property (nonatomic, copy)     NSString    *sshPort;
@property (nonatomic, copy)     NSString    *sshUser;
@property (nonatomic, copy)     NSString    *sshPassword;

@property (nonatomic, copy)     NSString    *adbSerial;
@property (nonatomic, copy)     NSString    *scrcpyServer;

@property (nonatomic, copy)     NSString    *coreVersion;
@property (nonatomic, copy)     NSString    *appVersion;

+(ScrcpyParams *)sharedParams;
+(void)setParamsWithServer:(NSString *)server
                      port:(NSString *)port
                      user:(NSString *)user
                  password:(NSString *)password
                  serial:(NSString *)serial;
@end
