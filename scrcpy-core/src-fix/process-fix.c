//
//  process-fix.c
//  scrcpy-core
//
//  Created by Ethan on 2021/12/10.
//

#define sc_process_wait(...)   sc_process_wait_unused(__VA_ARGS__)
#define sc_process_terminate(...)   sc_process_terminate_unused(__VA_ARGS__)

#include "sys/unix/process.c"
#include "scrcpy_bridge.h"

#undef sc_process_wait
#undef sc_process_terminate

sc_exit_code
sc_process_wait(pid_t pid, bool close) {
    scrcpy_thread_wait(pid);
    return 0;
}

bool
sc_process_terminate(pid_t pid) {
    scrcpy_thread_exit(pid);
    return true;
}
