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

bool
is_regular_file(const char *path) {
    printf("=> is_regular_file: %s\n", path);
    return true;
}

enum process_result
process_execute(const char *const argv[], pid_t *pid) {
    *pid = 1000;
    return ssh_exec(argv);
}

bool
process_check_success(process_t proc, const char *name, bool close) {
    printf("=> process_check_success: %s\n", name);
    return true;
}

exit_code_t
process_wait(pid_t pid, bool close) {
    // use sleep to fake wait status
    // TODO: add cancel signal or control flag
    while (1) {
        sleep(2);
    }
    return 0;
}

SDL_Renderer * SDL_CreateRenderer_fix(SDL_Window * window, int index, Uint32 flags) {
    SDL_Renderer *renderer = SDL_CreateRenderer(window, index, flags);
    SDL_RenderSetScale(renderer, screen_scale(), screen_scale());
    return renderer;
}
