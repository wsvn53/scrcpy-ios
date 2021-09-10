//
//  SDLUIKitDelegate+OpenURL.m
//  SDLUIKitDelegate+OpenURL
//
//  Created by Ethan on 2021/9/10.
//

#import "SDLUIKitDelegate+OpenURL.h"
#import "SchemeHandler.h"
#import "ScrcpyViewController.h"
#import "ScrcpyParams.h"

@implementation SDLUIKitDelegate (OpenURL)

-(BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
    NSLog(@"> Scrcpy: %@", url.absoluteURL);
    
    [SchemeHandler URLToScrcpyParams:url];
    
    // AutoConnect
    ScrcpyParams.sharedParams.autoConnectOnLoad = YES;
    
    // Post connect
    [[NSNotificationCenter defaultCenter] postNotificationName:kConnectWithSchemeNotification object:nil];
    
    return YES;
}

@end
