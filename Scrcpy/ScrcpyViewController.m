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

#define   kSDLDidCreateRendererNotification   @"kSDLDidCreateRendererNotification"
int scrcpy_main(int argc, char *argv[]);

@interface ScrcpyViewController ()

@property (weak, nonatomic) IBOutlet UIButton *connectButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicatorView;

@property (weak, nonatomic) IBOutlet UITextField *sshServer;
@property (weak, nonatomic) IBOutlet UITextField *sshPort;
@property (weak, nonatomic) IBOutlet UITextField *sshUser;
@property (weak, nonatomic) IBOutlet UITextField *sshPassword;
@property (weak, nonatomic) IBOutlet UITextField *adbSerial;

@end

@implementation ScrcpyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupViews];
    [self loadForm];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(resetViews)
                                               name:kSDLDidCreateRendererNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
//    [self autoStartScrcpy];
}

- (void)setupViews {
    self.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    
    // Custom navigationBar
    UINavigationBarAppearance* navBarAppearance = [self.navigationController.navigationBar standardAppearance];
    [navBarAppearance configureWithOpaqueBackground];
    navBarAppearance.titleTextAttributes = @{NSForegroundColorAttributeName: UIColor.whiteColor};
    navBarAppearance.largeTitleTextAttributes = @{NSForegroundColorAttributeName: UIColor.whiteColor};
    navBarAppearance.backgroundColor = [UIColor colorWithRed:0x33/255.f
                                                       green:0x99/255.f
                                                        blue:0x33/255.f
                                                       alpha:1.0f];;
    self.navigationController.navigationBar.standardAppearance = navBarAppearance;
    self.navigationController.navigationBar.scrollEdgeAppearance = navBarAppearance;
    
    // IndicatorView
    [self.indicatorView stopAnimating];
}

- (void)loadForm {
    // Load form UserDefaults
    self.sshServer.text = [SSHParams sharedParams].sshServer;
    self.sshPort.text = [SSHParams sharedParams].sshPort;
    self.sshUser.text = [SSHParams sharedParams].sshUser;
    self.sshPassword.text = [SSHParams sharedParams].sshPassword;
}

#pragma mark - Actions

- (void)showAlert:(NSString *)message {
    NSError *error = [NSError errorWithDomain:@"scrcpy" code:0 userInfo:@{
        NSLocalizedDescriptionKey : message,
    }];
    [error showAlert];
}

- (IBAction)startScrcpy:(id)sender {
    // Check SSH parameters
    NSString *server = self.sshServer.text;
    NSString *port   = self.sshPort.text;
    NSString *user   = self.sshUser.text;
    NSString *password = self.sshPassword.text;
    
    if (server == nil || server.length == 0) {
        [self showAlert:@"SSH Server is required!"];
        return;
    }
    
    if (port == nil || port.length == 0) {
        [self showAlert:@"SSH Port is required!"];
        return;
    }

    if (user == nil || user.length == 0) {
        [self showAlert:@"SSH User is required!"];
        return;
    }
    
    if (password == nil || password.length == 0) {
        [self showAlert:@"SSH Password is required!"];
        return;
    }

    [SSHParams setParamsWithServer:server
                              port:port
                              user:user
                          password:password];
    [self performSelector:@selector(scrcpyMain) withObject:nil afterDelay:0];
}

- (void)autoStartScrcpy {
    // Check SSH parameters
    NSString *server = self.sshServer.text;
    NSString *port   = self.sshPort.text;
    NSString *user   = self.sshUser.text;
    NSString *password = self.sshPassword.text;
    
    if (server.length == 0 || port.length == 0 ||
        user.length == 0 || password.length == 0) {
        NSLog(@"IGNORE AutoStart scrcpy!");
        return;
    }
    
    [SSHParams setParamsWithServer:server
                              port:port
                              user:user
                          password:password];
    [self performSelector:@selector(scrcpyMain) withObject:nil afterDelay:0];
}

- (void)scrcpyMain {
    // Disable all textfields
    [self toggleControlsEnabled:NO];

    // Show indicator animation
    [self.indicatorView startAnimating];
    
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

@end
