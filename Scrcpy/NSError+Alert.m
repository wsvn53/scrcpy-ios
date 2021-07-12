//
//  NSError+Alert.m
//  Scrcpy
//
//  Created by Ethan on 2021/7/12.
//

#import "NSError+Alert.h"
#import <UIKit/UIKit.h>

@implementation NSError (Alert)

- (void)showAlert {
    [self showAlertMain];
}

- (void)showAlertMain {
    static BOOL presenting = NO;
    if (presenting == YES) {
        return;
    }
    presenting = YES;

    NSString *errorMsg = self.userInfo[NSLocalizedDescriptionKey];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Scrcpy"
                                                                   message:errorMsg
                                                            preferredStyle:(UIAlertControllerStyleAlert)];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:(UIAlertActionStyleDefault) handler:nil]];
    UIApplication *app = UIApplication.sharedApplication;
    for (UIWindow *window in app.windows) {
        if (window.isKeyWindow) {
            [window.rootViewController presentViewController:alert animated:YES completion:^{
                presenting = NO;
            }];
        }
    }
}

@end
