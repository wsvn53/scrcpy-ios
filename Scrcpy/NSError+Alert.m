//
//  NSError+Alert.m
//  Scrcpy
//
//  Created by Ethan on 2021/7/12.
//

#import "NSError+Alert.h"
#import <UIKit/UIKit.h>
#import "NSString+Utils.h"

@implementation NSError (Alert)

- (void)showAlert {
    if ([[NSThread currentThread] isMainThread]) {
        [self showAlertMain];
    } else {
        [self performSelectorOnMainThread:@selector(showAlertMain) withObject:nil waitUntilDone:YES];
    }
}

- (void)showAlertMain {
    NSString *errorMsg = self.userInfo[NSLocalizedDescriptionKey];
    errorMsg = errorMsg.isValid ? self.description : errorMsg;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Scrcpy" message:errorMsg preferredStyle:(UIAlertControllerStyleAlert)];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:(UIAlertActionStyleDefault) handler:nil]];
    UIApplication *app = UIApplication.sharedApplication;
    UIWindow *keyWindow = nil;
    for (UIWindow *window in app.windows) {
        keyWindow = window.isKeyWindow ? window : keyWindow;
    }
    [keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
}

@end
