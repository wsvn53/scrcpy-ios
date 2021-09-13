//
//  ssh.h
//  scrcpy-fix
//
//  Created by Ethan on 2021/7/8.
//

#import <Foundation/Foundation.h>
#import <util/process.h>
#import "ExecStatus.h"
#import "ScrcpyParams.h"

enum process_result ssh_exec(const char *const argv[]);
bool ssh_forward(uint16_t port);
bool ssh_reverse(uint16_t port);
void scrcpy_shutdown(void);
