//
//  fix.c
//  libscrcpy
//
//  Created by Ethan on 2021/7/7.
//

#include "fix.h"
#include <stdbool.h>
#include <util/process.h>

bool
is_regular_file(const char *path) {
    printf("=> is_regular_file: %s\n", path);
    return true;
}

enum process_result
process_execute(const char *const argv[], pid_t *pid) {
    printf("=> process_execute: %s\n", argv[0]);
    *pid = 1000;
    return PROCESS_SUCCESS;
}

bool
process_check_success(process_t proc, const char *name, bool close) {
    printf("=> process_execute: %s\n", name);
    return true;
}
