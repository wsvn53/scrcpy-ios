//
//  server-fix.c
//  scrcpy-core
//
//  Created by Ethan on 2021/12/10.
//

#define sc_file_is_regular(...)     sc_file_is_regular_fix(__VA_ARGS__)

#include "server.c"

#undef execute_server

// fix sc_file_is_regular to always true
bool sc_file_is_regular_fix(const char *path) {
    return true;
}
