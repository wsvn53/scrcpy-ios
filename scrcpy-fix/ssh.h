//
//  ssh.h
//  scrcpy-fix
//
//  Created by Ethan on 2021/7/8.
//

#import <Foundation/Foundation.h>
#import <util/process.h>

enum process_result ssh_exec(const char *const argv[]);
bool ssh_forward(const char *local_addr, const char *remote_addr);
bool ssh_reverse(uint16_t port);

@interface SSHParams : NSObject
@property (nonatomic, copy)     NSString    *sshServer;
@property (nonatomic, copy)     NSString    *sshPort;
@property (nonatomic, copy)     NSString    *sshUser;
@property (nonatomic, copy)     NSString    *sshPassword;

+(SSHParams *)sharedParams;
+(void)setParamsWithServer:(NSString *)server
                      port:(NSString *)port
                      user:(NSString *)user
                  password:(NSString *)password;
@end
