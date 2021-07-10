//
//  fix.c
//  libscrcpy
//
//  Created by Ethan on 2021/7/7.
//

#import "fix.h"
#import <stdbool.h>
#import <util/process.h>
#import <util/net.h>
#import "ssh.h"
#import <SDL2/SDL.h>
#import "utils.h"
#import "util/thread.h"

// control wait-server thread exit
static bool bScrcpyServerIsStopping = false;

// handle is_regular_file to ignore check local scrcpy-server exists
bool
is_regular_file(const char *path) {
    printf("=> is_regular_file: %s\n", path);
    return true;
}

// handle process_result to use ssh_exec
enum process_result
process_execute(const char *const argv[], pid_t *pid) {
    *pid = 1000;
    return ssh_exec(argv);
}

// handle process_check_success to always true
bool
process_check_success(process_t proc, const char *name, bool close) {
    printf("=> process_check_success: %s\n", name);
    return true;
}

// handle process_wait to forbidden scrcpy exit
exit_code_t
process_wait(pid_t pid, bool close) {
    // use sleep to fake wait status
    // TODO: add cancel signal or control flag
    while (bScrcpyServerIsStopping == false) {
        sleep(2);
    }
    bScrcpyServerIsStopping = false;
    return 0;
}

// handle sc_thread_join to stop wait-server thread
void
sc_thread_join(sc_thread *thread, int *status) {
    bScrcpyServerIsStopping = true;
}

// handle SDL_CreateRenderer to set scale
SDL_Renderer * SDL_CreateRenderer_fix(SDL_Window * window, int index, Uint32 flags) {
    SDL_Renderer *renderer = SDL_CreateRenderer(window, index, flags);
    SDL_RenderSetScale(renderer, screen_scale(), screen_scale());
    [NSNotificationCenter.defaultCenter postNotificationName:kSDLDidCreateRendererNotification object:nil];
    return renderer;
}
