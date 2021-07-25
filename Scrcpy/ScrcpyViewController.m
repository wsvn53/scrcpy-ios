//
//  ScrcpyViewController.m
//  Scrcpy
//
//  Created by Ethan on 2021/7/9.
//

#import "ScrcpyViewController.h"
#import <SDL2/SDL.h>
#import "ssh.h"
#import "NSError+Alert.h"
#import "utils.h"

#define   kSDLDidCreateRendererNotification   @"kSDLDidCreateRendererNotification"
int scrcpy_main(int argc, char *argv[]);

#define   CheckParam(var, name)    if (var == nil || var.length == 0) { \
    [self showAlert:[name stringByAppendingString:@" is required!"]];    \
    return;     \
}

@interface ScrcpyViewController ()

@property (weak, nonatomic) IBOutlet UIButton *connectButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicatorView;

@property (weak, nonatomic) IBOutlet UITextField *sshServer;
@property (weak, nonatomic) IBOutlet UITextField *sshPort;
@property (weak, nonatomic) IBOutlet UITextField *sshUser;
@property (weak, nonatomic) IBOutlet UITextField *sshPassword;
@property (weak, nonatomic) IBOutlet UITextField *adbSerial;
@property (weak, nonatomic) IBOutlet UILabel *scrcpyServer;

@end

@implementation ScrcpyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupViews];
    [self loadForm];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(resetViews)
                                               name:kSDLDidCreateRendererNotification object:nil];
}

- (void)setupViews {
    self.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    
    // Custom navigationBar
    UINavigationBarAppearance* navBarAppearance = [self.navigationController.navigationBar standardAppearance];
    [navBarAppearance configureWithOpaqueBackground];
    navBarAppearance.titleTextAttributes = @{NSForegroundColorAttributeName: UIColor.whiteColor};
    navBarAppearance.largeTitleTextAttributes = @{NSForegroundColorAttributeName: UIColor.whiteColor};
    navBarAppearance.backgroundColor = [UIColor colorWithRed:0x33/255.f green:0x99/255.f blue:0x33/255.f alpha:1.0f];
    self.navigationController.navigationBar.standardAppearance = navBarAppearance;
    self.navigationController.navigationBar.scrollEdgeAppearance = navBarAppearance;
    
    // IndicatorView
    [self.indicatorView stopAnimating];
    
    // Custom Connect Button
    [self.connectButton setBackgroundImage:UIColorAsImage(UIColor.systemGray4Color, self.connectButton.bounds.size) forState:(UIControlStateDisabled)];
    [self.connectButton setBackgroundImage:UIColorAsImage(self.connectButton.backgroundColor, self.connectButton.bounds.size) forState:(UIControlStateNormal)];
    
    // Text Editing Delegate
    self.sshServer.delegate = (id<UITextFieldDelegate>)self;
    self.sshPort.delegate = (id<UITextFieldDelegate>)self;
    self.sshUser.delegate = (id<UITextFieldDelegate>)self;
    self.sshPassword.delegate = (id<UITextFieldDelegate>)self;
    self.adbSerial.delegate = (id<UITextFieldDelegate>)self;
}

- (void)loadForm {
    // Load form UserDefaults
    self.sshServer.text = [SSHParams sharedParams].sshServer;
    self.sshPort.text = [SSHParams sharedParams].sshPort;
    self.sshUser.text = [SSHParams sharedParams].sshUser;
    self.sshPassword.text = [SSHParams sharedParams].sshPassword;
    self.adbSerial.text = [SSHParams sharedParams].adbSerial;
    self.scrcpyServer.text = [SSHParams sharedParams].scrcpyServer;
}

#pragma mark - Actions

- (void)showAlert:(NSString *)message {
    NSError *error = [NSError errorWithDomain:@"scrcpy" code:0 userInfo:@{
        NSLocalizedDescriptionKey : message,
    }];
    [error showAlert];
}

- (IBAction)startScrcpy:(id)sender {
    NSString *server = self.sshServer.text;
    NSString *port   = self.sshPort.text;
    NSString *user   = self.sshUser.text;
    NSString *password = self.sshPassword.text;
    NSString *serial = self.adbSerial.text;
    
    // Check & Save SSH connnection parameters
    CheckParam(server,  @"ssh server");
    CheckParam(port,    @"ssh port");
    CheckParam(user,    @"ssh user");
    CheckParam(password,    @"password");
    [SSHParams setParamsWithServer:server port:port user:user password:password serial:serial];
    
    // reset error status
    [[ExecStatus sharedStatus] resetStatus];
    
    // Disable all textfields
    [self toggleControlsEnabled:NO];

    // Show indicator animation
    [self.indicatorView startAnimating];
    
    // Start scrcpy by detach from current stack
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self preConnectWithLocalNetwork:server port:[port integerValue] completion:^{
            [self performSelectorOnMainThread:@selector(scrcpyMain) withObject:nil waitUntilDone:NO];
        }];
    });
}

- (void)toggleControlsEnabled:(BOOL)enabled {
    self.sshServer.enabled = enabled;
    self.sshPort.enabled = enabled;
    self.sshUser.enabled = enabled;
    self.sshPassword.enabled = enabled;
    self.adbSerial.enabled = enabled;
    self.connectButton.enabled = enabled;
}

- (void)resetViews {
    self.connectButton.enabled = YES;
    [self.indicatorView stopAnimating];
}

#pragma mark - Scrcpy

- (void)scrcpyMain {
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, NO);
    SDL_iPhoneSetEventPump(SDL_TRUE);

    // Because after SDL proxied didFinishLauch, PumpEvent will set to FASLE
    // So we need to set to TRUE in order to handle UI events
    if (self.adbSerial.text == nil || self.adbSerial.text.length == 0) {
        char *scrcpy_argv[4] = { "scrcpy", "-V", "debug", "-f" };
        scrcpy_main(4, scrcpy_argv);
    } else {
        char *adb_serial = (char *)self.adbSerial.text.UTF8String;
        char *scrcpy_argv[6] = { "scrcpy", "-V", "debug", "-f", "-s", adb_serial };
        scrcpy_main(6, scrcpy_argv);
    }
    
    [self toggleControlsEnabled:YES];
    [self.indicatorView stopAnimating];
    
    NSLog(@"Scrcpy STOPPED.");
}

#pragma mark - Utils

- (void)preConnectWithLocalNetwork:(NSString *)host port:(NSInteger)port completion:(void(^)(void))completion {
    NSURLSessionConfiguration *sessConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessConfiguration.waitsForConnectivity = YES;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessConfiguration];
    static NSURLSessionStreamTask *streamTask = nil;
    streamTask = [session streamTaskWithHostName:host port:port];
    [streamTask readDataOfMinLength:1 maxLength:1 timeout:30.f completionHandler:^(NSData * _Nullable_result data, BOOL atEOF, NSError * _Nullable error) {
        NSLog(@"Data: %@", data);
        NSLog(@"Error: %@", error);
        
        // No errors, user allowed Local Network permission
        if (error == nil) {
            completion();
            return;
        }
        
        // Otherwise, show error message
        [error showAlert];
    }];
    [streamTask resume];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end
