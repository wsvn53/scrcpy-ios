//
//  adb-fix.c
//  scrcpy-core
//
//  Created by Ethan on 2021/12/8.
//

#import "scrcpy_bridge.h"

#define adb_get_serialno(...)   adb_get_serialno_unused(__VA_ARGS__)
#define adb_push(...)           adb_push_unused(__VA_ARGS__)
#define adb_reverse(...)           adb_reverse_unused(__VA_ARGS__)
#define adb_reverse_remove(...)           adb_reverse_remove_unused(__VA_ARGS__)
#define adb_forward(...)           adb_forward_unused(__VA_ARGS__)
#define adb_forward_remove(...)           adb_forward_remove_unused(__VA_ARGS__)
#define adb_execute(...)           adb_execute_unused(__VA_ARGS__)

#include "adb.c"

#undef adb_get_serialno
#undef adb_push
#undef adb_reverse
#undef adb_reverse_remove
#undef adb_forward
#undef adb_forward_remove
#undef adb_execute

/**
 * adb_complete: append adb [-s serial]
 */
void adb_complete(const char *out_cmd[], const char *serial, const char *const adb_cmd[], size_t *len) {
    if (serial != NULL && strlen(serial) > 0) {
        *len += 3;
        out_cmd[0] = "adb";
        out_cmd[1] = "-s";
        out_cmd[2] = serial;
        
        for (int i = 3; i < *len; i++) {
            out_cmd[i] = adb_cmd[i - 3];
        }
        return;
    }
    
    *len += 1;
    out_cmd[0] = "adb";
    for (int i = 1; i < *len; i++) {
        out_cmd[i] = adb_cmd[i-1];
    }
}

/**
 * Handle adb_get_serialno to execute on ssh server
 */
char *
adb_get_serialno(struct sc_intr *intr, unsigned flags) {
    const char *const adb_cmd[] = {"adb", "get-serialno"};
    bool success;
    const char *result = scrcpy_ssh_execute(adb_cmd, ARRAY_LEN(adb_cmd), false, &success);
    return success && result != NULL ? strdup(result) : NULL;
}

/**
 * Handle adb_push to execute on ssh server
 */
bool
adb_push(struct sc_intr *intr, const char *serial, const char *local,
         const char *remote, unsigned flags) {
    // upload scrcpy-server to remote first
    bool uploaded = scrcpy_ssh_upload("scrcpy-server", local);
    if (uploaded == false) {
        return false;
    }
    
    // then execute adb push command on remote ssh server
    const char *cmds[256];
    size_t len = 3;
    const char *adb_cmd[] = {"push", local, remote};
    adb_complete(cmds, serial, adb_cmd, &len);
    bool success;
    scrcpy_ssh_execute(cmds, len, false, &success);
    
    return success;
}

/**
 * Handle adb_reverse to open network port
 */
bool
adb_reverse(struct sc_intr *intr, const char *serial,
            const char *device_socket_name, uint16_t local_port,
            unsigned flags) {
    char local[4 + 5 + 1]; // tcp:PORT
    char remote[108 + 14 + 1]; // localabstract:NAME
    sprintf(local, "tcp:%" PRIu16, local_port);
    snprintf(remote, sizeof(remote), "localabstract:%s", device_socket_name);
    
    const char *const adb_cmd[] = {"reverse", remote, local};
    const char *cmds[256];
    size_t len = ARRAY_LEN(adb_cmd);
    adb_complete(cmds, serial, adb_cmd, &len);
    
    bool success;
    scrcpy_ssh_execute(cmds, len, false, &success);
    
    // ssh reverse local network with remote network
    if (success) {
        return scrcpy_ssh_reverse(local_port);
    }
    
    return false;
}

bool
adb_reverse_remove(struct sc_intr *intr, const char *serial,
                   const char *device_socket_name, unsigned flags) {
    char remote[108 + 14 + 1]; // localabstract:NAME
    snprintf(remote, sizeof(remote), "localabstract:%s", device_socket_name);
    const char *const adb_cmd[] = {"reverse", "--remove", remote};
    const char *cmds[256];
    size_t len = ARRAY_LEN(adb_cmd);
    adb_complete(cmds, serial, adb_cmd, &len);

    bool success;
    scrcpy_ssh_execute(cmds, len, false, &success);
    return success;
}

/**
 * Handle adb_forward to execute on ssh server
 */
bool
adb_forward(struct sc_intr *intr, const char *serial, uint16_t local_port,
            const char *device_socket_name, unsigned flags) {
    char local[4 + 5 + 1]; // tcp:PORT
    char remote[108 + 14 + 1]; // localabstract:NAME
    sprintf(local, "tcp:%" PRIu16, local_port);
    snprintf(remote, sizeof(remote), "localabstract:%s", device_socket_name);
    const char *const adb_cmd[] = {"forward", local, remote};

    const char *cmds[256];
    size_t len = ARRAY_LEN(adb_cmd);
    adb_complete(cmds, serial, adb_cmd, &len);
    
    bool success;
    scrcpy_ssh_execute(cmds, len, false, &success);
    
    // ssh forward remote network with local network
    if (success) {
        return scrcpy_ssh_forward(local_port);
    }
    return false;
}

bool
adb_forward_remove(struct sc_intr *intr, const char *serial,
                   uint16_t local_port, unsigned flags) {
    char local[4 + 5 + 1]; // tcp:PORT
    sprintf(local, "tcp:%" PRIu16, local_port);
    const char *const adb_cmd[] = {"forward", "--remove", local};
    const char *cmds[256];
    size_t len = ARRAY_LEN(adb_cmd);
    adb_complete(cmds, serial, adb_cmd, &len);
    
    bool success;
    scrcpy_ssh_execute(cmds, len, false, &success);
    return success;
}

/**
 * Handle adb_execute to run adb commands
 */
sc_pid
adb_execute(const char *serial, const char *const adb_cmd[], size_t len,
            unsigned flags) {
    const char *cmds[256];
    adb_complete(cmds, serial, adb_cmd, &len);
    return scrcpy_ssh_execute_bg(cmds, len);
}
