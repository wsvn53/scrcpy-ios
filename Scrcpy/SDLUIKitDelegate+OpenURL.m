//
//  SDLUIKitDelegate+OpenURL.m
//  SDLUIKitDelegate+OpenURL
//
//  Created by Ethan on 2021/9/10.
//

#import "SDLUIKitDelegate+OpenURL.h"
#import "ScrcpyViewController.h"
#import "ScrcpyParams.h"
#import <SDL2/SDL.h>
#import "scrcpy_bridge.h"

@implementation SDLUIKitDelegate (OpenURL)

-(BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
    NSLog(@"> Scrcpy: %@", url.absoluteURL);
    
    // AutoConnect
    ScrcpyParams.sharedParams.autoConnectURL = url;
    
    // Post connect
    [NSNotificationCenter.defaultCenter postNotificationName:kConnectWithSchemeNotification object:nil];
    
    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    SDL_OnApplicationDidEnterBackground();
    
    NSLog(@"Time Remaining: %@",  @(application.backgroundTimeRemaining));
    __block UIBackgroundTaskIdentifier taskID = [application beginBackgroundTaskWithExpirationHandler:^{
        [application endBackgroundTask:taskID];
        NSLog(@"Force exit.");
        scrcpy_quit();
    }];
}

@end
