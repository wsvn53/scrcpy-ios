//
//  scrcpy-fix.c
//  scrcpy-core
//  > this file is created to fix/tuning srouce code of scrcpy core
//
//  Created by Ethan on 2021/12/7.
//

#include <stdbool.h>
#include "input_manager.h"

bool
input_manager_handle_event_fix(struct input_manager *im, SDL_Event *event);

#define input_manager_handle_event(...)  input_manager_handle_event_fix(__VA_ARGS__)

#include "scrcpy.c"

#undef input_manager_handle_event

/**
 * Handle input_manager to allow null when send a Restart codec event
 */
bool
input_manager_handle_event_fix(struct input_manager *im, SDL_Event *event) {
    static struct input_manager *global_im = NULL;
    global_im = im ? : global_im;
    
    // sometimes maybe control connect haven't ready
    if (global_im == NULL) {
        return false;
    }
    
    return input_manager_handle_event(global_im, event);
}
