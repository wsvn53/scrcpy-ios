//
//  ScrcpyViewController.m
//  Scrcpy
//
//  Created by Ethan on 2021/7/9.
//

#import "ScrcpyViewController.h"
#import "ScrcpyBridge.h"
#import "NSError+Alert.h"
#import "SDLUIKitDelegate+OpenURL.h"
#import "SchemeHandler.h"
#import "ScrcpyParams.h"
#import "screen-fix.h"

#define   CheckParam(var, name)    if (var == nil || var.length == 0) { \
    [self showAlert:[name stringByAppendingString:@" is required!"]];    \
    return;     \
}

float screen_scale(void) {
    if ([UIScreen.mainScreen respondsToSelector:@selector(nativeScale)]) {
        return UIScreen.mainScreen.nativeScale;
    }
    return UIScreen.mainScreen.scale;
}

UIKIT_EXTERN UIImage * __nullable UIColorAsImage(UIColor * __nonnull color, CGSize size) {
    
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, [UIScreen mainScreen].scale);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context,color.CGColor);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@interface ScrcpyViewController ()
@property (nonatomic, strong)   ScrcpyBridge    *scrcpyBridge;

@property (weak, nonatomic) IBOutlet UIButton *connectButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicatorView;

@property (weak, nonatomic) IBOutlet UITextField *sshServer;
@property (weak, nonatomic) IBOutlet UITextField *sshPort;
@property (weak, nonatomic) IBOutlet UITextField *sshUser;
@property (weak, nonatomic) IBOutlet UITextField *sshPassword;
@property (weak, nonatomic) IBOutlet UITextField *adbSerial;
@property (weak, nonatomic) IBOutlet UILabel *scrcpyServer;
@property (weak, nonatomic) IBOutlet UILabel *coreVersion;
@property (weak, nonatomic) IBOutlet UILabel *appVersion;
@property (weak, nonatomic) IBOutlet UITextField *maxSize;
@property (weak, nonatomic) IBOutlet UISegmentedControl *bitRate;
@property (weak, nonatomic) IBOutlet UISwitch *screenOff;
@property (nonatomic, copy) NSString *bitRateText;
@property (nonatomic, copy) NSNumber *screenOffValue;

@end

@implementation ScrcpyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupViews];
    
    [self bindForm];
    [self loadForm];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(resetViews)
                                               name:kSDLDidCreateRendererNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(launchWithURLScheme)
                                               name:kConnectWithSchemeNotification object:nil];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self autoConnect];
    });
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
    [self.connectButton setBackgroundImage:UIColorAsImage([UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1], self.connectButton.bounds.size) forState:(UIControlStateDisabled)];
    [self.connectButton setBackgroundImage:UIColorAsImage(self.connectButton.backgroundColor, self.connectButton.bounds.size) forState:(UIControlStateNormal)];
    
    // Text Editing Delegate
    self.sshServer.delegate = (id<UITextFieldDelegate>)self;
    self.sshPort.delegate = (id<UITextFieldDelegate>)self;
    self.sshUser.delegate = (id<UITextFieldDelegate>)self;
    self.sshPassword.delegate = (id<UITextFieldDelegate>)self;
    self.adbSerial.delegate = (id<UITextFieldDelegate>)self;
    self.maxSize.delegate = (id<UITextFieldDelegate>)self;
}

- (void)bindForm {
    ScrcpyParams_bind(self.sshServer.text, ScrcpyParams.sharedParams.sshServer, @"ssh_server", @"");
    ScrcpyParams_bind(self.sshPort.text, ScrcpyParams.sharedParams.sshPort, @"ssh_port", @"22");
    ScrcpyParams_bind(self.sshUser.text, ScrcpyParams.sharedParams.sshUser, @"ssh_user", @"");
    ScrcpyParams_bind(self.sshPassword.text, ScrcpyParams.sharedParams.sshPassword, @"ssh_password", @"");
    ScrcpyParams_bind(self.adbSerial.text, ScrcpyParams.sharedParams.adbSerial, @"adb_serial", @"");
    ScrcpyParams_bind(self.maxSize.text, ScrcpyParams.sharedParams.maxSize, @"max_size", @"");
    ScrcpyParams_bind(self.bitRateText, ScrcpyParams.sharedParams.bitRate, @"bit_rate", @"");
    ScrcpyParams_bind(self.screenOffValue, ScrcpyParams.sharedParams.screenOff, @"screen_off", @YES);
    
    ScrcpyParamsBind(^{
        self.scrcpyServer.text = ScrcpyParams.sharedParams.scrcpyServer;
    }, ^{});
    ScrcpyParamsBind(^{
        self.coreVersion.text = ScrcpyParams.sharedParams.coreVersion;
    }, ^{});
    ScrcpyParamsBind(^{
        self.appVersion.text = ScrcpyParams.sharedParams.appVersion;
    }, ^{});
}

- (void)loadForm {
    // Load form UserDefaults
    [ScrcpyParams.sharedParams loadDefaults];
}

- (void)launchWithURLScheme {
    if (self.viewLoaded == NO) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self autoConnect];
    });
}

- (void)autoConnect {
    if (ScrcpyParams.sharedParams.autoConnectURL == nil) return;
    
    // Parse URL params
    [SchemeHandler URLToScrcpyParams:ScrcpyParams.sharedParams.autoConnectURL];
    ScrcpyParams.sharedParams.autoConnectURL = nil;
    
    // Current remote control is connected, disconnect first
    if (self.view.window != nil && self.view.window.isKeyWindow == NO) {
        NSLog(@"> self.view.window is not keyWindow");
        return;
    }
    
    // Disable all textfields
    [self toggleControlsEnabled:NO];

    // Show indicator animation
    [self.indicatorView startAnimating];
    
    // Start scrcpy main entry
    [self scrcpyMain];
}

#pragma mark - Getters & Setters

-(NSNumber *)screenOffValue {
    return @(self.screenOff.isOn);
}

-(void)setScreenOffValue:(NSNumber *)screenOffValue {
    self.screenOff.on = [screenOffValue boolValue];
}

-(NSString *)bitRateText {
    return [self.bitRate titleForSegmentAtIndex:self.bitRate.selectedSegmentIndex];
}

-(void)setBitRateText:(NSString *)bitRateText {
    self.bitRate.selectedSegmentIndex = ^NSInteger(void){
        for (NSInteger i = 0; i < self.bitRate.numberOfSegments; i++) {
            if ([[self.bitRate titleForSegmentAtIndex:i] isEqualToString:ScrcpyParams.sharedParams.bitRate]) {
                return i;
            }
        }
        return 2;
    }();
}

#pragma mark - Actions

- (void)showAlert:(NSString *)message {
    NSError *error = [NSError errorWithDomain:@"scrcpy" code:0 userInfo:@{
        NSLocalizedDescriptionKey : message,
    }];
    [error showAlert];
}

- (IBAction)startScrcpy:(id)sender {
    // Check & Save SSH connnection parameters
    CheckParam(self.sshServer.text,  @"ssh server");
    CheckParam(self.sshPort.text,    @"ssh port");
    CheckParam(self.sshUser.text,    @"ssh user");
    CheckParam(self.sshPassword.text,    @"password");
    
    // Save parameters to defaults
    [ScrcpyParams.sharedParams saveDefaults];
    
    // Disable all textfields
    [self toggleControlsEnabled:NO];

    // Show indicator animation
    [self.indicatorView startAnimating];
    
    NSString *server = self.sshServer.text;
    NSString *port   = self.sshPort.text;
    
    // Start scrcpy by detach from current stack
    if ([self checkLocalNetworkPrompted:server]) {
        [self performSelectorOnMainThread:@selector(scrcpyMain) withObject:nil waitUntilDone:NO];
    } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [self preConnectWithLocalNetwork:server port:[port integerValue] completion:^{
                [self markLocalNetworkPrompted:server];
                [self performSelectorOnMainThread:@selector(scrcpyMain) withObject:nil waitUntilDone:NO];
            }];
        });
    }
}

- (void)toggleControlsEnabled:(BOOL)enabled {
    self.sshServer.enabled = enabled;
    self.sshPort.enabled = enabled;
    self.sshUser.enabled = enabled;
    self.sshPassword.enabled = enabled;
    self.adbSerial.enabled = enabled;
    self.maxSize.enabled = enabled;
    self.bitRate.enabled = enabled;
    self.connectButton.enabled = enabled;
}

- (void)resetViews {
    [self toggleControlsEnabled:YES];
    [self.indicatorView stopAnimating];
}

#pragma mark - Scrcpy

- (void)scrcpyMain {
    // Here in case there is no opportunity to perform UI animations and other changes
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, NO);
    
    // Reset context
    [self.scrcpyBridge resetContext];

    NSString *bitRate = ScrcpyParams.sharedParams.bitRate;
    NSMutableArray *scrcpyOptions = [NSMutableArray arrayWithArray:@[
        @"scrcpy", @"-V", @"debug", @"-f", @"--max-fps", @"60", @"--bit-rate", bitRate
    ]];
    
    // Add serial option
    if (ScrcpyParams.sharedParams.adbSerial.length > 0) {
        [scrcpyOptions addObjectsFromArray:@[ @"-s", ScrcpyParams.sharedParams.adbSerial ]];
    }
    
    // Add maxSize option
    if (ScrcpyParams.sharedParams.maxSize.length > 0) {
        [scrcpyOptions addObjectsFromArray:@[ @"--max-size", ScrcpyParams.sharedParams.maxSize ]];
    }
    
    // Add screenOff option
    if (ScrcpyParams.sharedParams.screenOff.boolValue) {
        [scrcpyOptions addObjectsFromArray:@[ @"--turn-screen-off" ]];
    }
    
    // Start scrcpy
    [self.scrcpyBridge startWith:scrcpyOptions];
    
    [self toggleControlsEnabled:YES];
    [self.indicatorView stopAnimating];
    
    NSLog(@"Scrcpy STOPPED.");
    [self.scrcpyBridge shutdown];
}

#pragma mark - Getter

-(ScrcpyBridge *)scrcpyBridge {
    _scrcpyBridge = _scrcpyBridge ? : ([[ScrcpyBridge alloc] init]);
    return _scrcpyBridge;
}

#pragma mark - Utils

- (void)preConnectWithLocalNetwork:(NSString *)host port:(NSInteger)port completion:(void(^)(void))completion {
    NSURLSessionConfiguration *sessConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessConfiguration.waitsForConnectivity = YES;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessConfiguration];
    static NSURLSessionStreamTask *streamTask = nil;
    streamTask = [session streamTaskWithHostName:host port:port];
    [streamTask readDataOfMinLength:1 maxLength:1 timeout:30.f completionHandler:^(NSData *data, BOOL atEOF, NSError *error) {
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

#define PromptedKey(host)   [@"P_" stringByAppendingString:host]

-(BOOL)checkLocalNetworkPrompted:(NSString *)host {
    return [NSUserDefaults.standardUserDefaults boolForKey:PromptedKey(host)];
}

-(void)markLocalNetworkPrompted:(NSString *)host {
    [NSUserDefaults.standardUserDefaults setBool:YES forKey:PromptedKey(host)];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end
