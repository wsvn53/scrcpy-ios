//
//  scrcpy_bridge.h
//  scrcpy-bridge
//
//  Created by Ethan on 2021/12/9.
//

#ifndef scrcpy_bridge_h
#define scrcpy_bridge_h

#include <stdio.h>
#include <stdbool.h>

void scrcpy_quit(void);
void scrcpy_thread_wait(pid_t pid);
void scrcpy_thread_exit(pid_t pid);

uint16_t scrcpy_ssh_execute_bg(const char *const ssh_cmd[], size_t len);
const char *scrcpy_ssh_execute(const char *const ssh_cmd[], size_t len, bool silent);
bool scrcpy_ssh_upload(const char *local, const char *remote);
bool scrcpy_ssh_reverse(uint16_t port);
bool scrcpy_ssh_forward(uint16_t port);

#endif /* scrcpy_bridge_h */
