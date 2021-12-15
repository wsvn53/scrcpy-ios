//
//  controller-fix.c
//  scrcpy-core
//
//  Created by Ethan on 2021/12/13.
//

#define     controller_join(...)        controller_join_orig(__VA_ARGS__)

#include "controller.c"

#undef      controller_join

/**
 * Handle controller_join to close control socket before wait thread exit
 */

void
controller_join(struct controller *controller) {
    LOGD("Closing control socket.");
    net_close(controller->control_socket);
    controller_join_orig(controller);
}
