//
//  main.m
//  Scrcpy
//
//  Created by Ethan on 2021/7/7.
//

#import <UIKit/UIKit.h>
#import "config.h"
#import <SDL2/SDL_main.h>
#import "ViewController.h"

int main(int argc, char * argv[]) {
    NSLog(@"Hello scrcpy v%s", SCRCPY_VERSION);
    
    static UIWindow *window = nil;
    window = [[UIWindow alloc] init];
    window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[ViewController new]];
    [window makeKeyAndVisible];
    
    return 0;
}
