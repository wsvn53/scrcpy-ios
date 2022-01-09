//
//  ScrcpyViewController.m
//  Scrcpy
//
//  Created by Ethan on 2021/7/9.
//

#import "ScrcpyViewController.h"
#import "ScrcpyBridge.h"
#import "NSError+Alert.h"
#import "NSString+Utils.h"
#import "SDLUIKitDelegate+Extend.h"
#import "SchemeHandler.h"
#import "ScrcpyParams.h"
#import "screen-fix.h"
#import "scrcpy_bridge.h"
#import "LogViewController.h"

#define   CheckParam(var, name)    if (var.isValid == NO) { \
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
@property (weak, nonatomic) IBOutlet UILabel *bitRate;
@property (weak, nonatomic) IBOutlet UIStepper *bitRateLower;
@property (weak, nonatomic) IBOutlet UIStepper *bitRateUpper;
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
    [self performSelector:@selector(autoConnect) withObject:nil afterDelay:0.1];
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
    
    // Stepper Events
    [self.bitRateLower addTarget:self action:@selector(bitRateChanged:) forControlEvents:UIControlEventTouchUpInside];
    [self.bitRateUpper addTarget:self action:@selector(bitRateChanged:) forControlEvents:UIControlEventTouchUpInside];
    
    // Navigation Bar
    UIBarButtonItem *moreItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"more"] style:(UIBarButtonItemStyleDone) target:self action:@selector(showMoreMenu:)];
    moreItem.tintColor = UIColor.whiteColor;
    self.navigationItem.rightBarButtonItem = moreItem;
}

static inline void AppendURLParams(NSMutableArray *queryItems, NSString *name, NSString *value) {
    if (value.isValid == NO) {
        return;
    }
    NSURLQueryItem *item = [NSURLQueryItem queryItemWithName:name value:value];
    [queryItems addObject:item];
}

-(void)copyURLScheme {
    CheckParam(self.sshServer.text,  @"ssh server");
    CheckParam(self.sshPort.text,    @"ssh port");
    CheckParam(self.sshUser.text,    @"ssh user");
    CheckParam(self.sshPassword.text,    @"password");
    
    NSString *base64Pass = [[self.sshPassword.text dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:(0)];
    NSString *urlString = [NSString stringWithFormat:@"scrcpy://%@:%@@%@:%@",
                           self.sshUser.text, base64Pass, self.sshServer.text, self.sshPort.text];
    NSURLComponents *scrcpyComponents = [NSURLComponents componentsWithURL:[NSURL URLWithString:urlString] resolvingAgainstBaseURL:NO];
    NSMutableArray *queryItems = [NSMutableArray new];
    
    // Append other parameters
    AppendURLParams(queryItems, @"adbSerial", self.adbSerial.text);
    AppendURLParams(queryItems, @"maxSize", self.maxSize.text);
    AppendURLParams(queryItems, @"bitRate", self.bitRateText);
    AppendURLParams(queryItems, @"screenOff", [self.screenOffValue stringValue]);
    
    [scrcpyComponents setQueryItems:queryItems];
    NSURL *scrcpyURL = [scrcpyComponents URL];
    NSLog(@"URL> %@", scrcpyURL);
    
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.URL = scrcpyURL;
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Copy URL" message:[NSString stringWithFormat:@"URL Copied:\n%@", scrcpyURL.absoluteString] preferredStyle:(UIAlertControllerStyleAlert)];
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:(UIAlertActionStyleCancel) handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

-(void)clearScrcpyForm {
    self.sshServer.text = @"";
    self.sshPort.text = @"22";
    self.sshUser.text = @"";
    self.sshPassword.text = @"";
    self.adbSerial.text = @"";
    self.maxSize.text = @"";
    self.screenOff.on = NO;
    [self setBitRateValue:4];
}

-(void)setBitRateValue:(NSInteger)value {
    self.bitRateLower.value = value;
    self.bitRateUpper.value = value;
    self.bitRate.text = [NSString stringWithFormat:@"%@M", @(value)];
}

-(void)bitRateChanged:(UIStepper *)stepper {
    [self setBitRateValue:stepper.value];
}

-(void)showScrcpyLogs {
    [self presentViewController:[LogViewController new] animated:YES completion:nil];
}

-(void)showMoreMenu:(id)sender {
    UIAlertController *moreController = [UIAlertController alertControllerWithTitle:@"More Actions" message:nil preferredStyle:(UIAlertControllerStyleActionSheet)];
    [moreController addAction: [UIAlertAction actionWithTitle:@"Copy URL Scheme" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"ACTION> Copy Current URL Scheme");
        [self copyURLScheme];
    }]];
    [moreController addAction:[UIAlertAction actionWithTitle:@"Clear Scrcpy Form" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"ACTION> Clear Scrcpy Form");
        [self clearScrcpyForm];
    }]];
    [moreController addAction:[UIAlertAction actionWithTitle:@"Show Scrcpy Logs" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"ACTION> Show Scrcpy Logs");
        [self showScrcpyLogs];
    }]];
    [moreController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:(UIAlertActionStyleCancel) handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"ACTION> Dismiss");
    }]];
    
    moreController.popoverPresentationController.sourceView = (UIView *)[self.navigationItem.rightBarButtonItem valueForKey:@"view"];
    [self presentViewController:moreController animated:YES completion:nil];
}

- (void)bindForm {
    ScrcpyParams_bind(self.sshServer.text, ScrcpyParams.sharedParams.sshServer, @"ssh_server", @"");
    ScrcpyParams_bind(self.sshPort.text, ScrcpyParams.sharedParams.sshPort, @"ssh_port", @"22");
    ScrcpyParams_bind(self.sshUser.text, ScrcpyParams.sharedParams.sshUser, @"ssh_user", @"");
    ScrcpyParams_bind(self.sshPassword.text, ScrcpyParams.sharedParams.sshPassword, @"ssh_password", @"");
    ScrcpyParams_bind(self.adbSerial.text, ScrcpyParams.sharedParams.adbSerial, @"adb_serial", @"");
    ScrcpyParams_bind(self.maxSize.text, ScrcpyParams.sharedParams.maxSize, @"max_size", @"");
    ScrcpyParams_bind(self.bitRateText, ScrcpyParams.sharedParams.bitRate, @"bit_rate", @"4M");
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
    [self performSelector:@selector(autoConnect) withObject:nil afterDelay:0.1];
}

- (void)autoConnect {
    if (ScrcpyParams.sharedParams.autoConnectURL == nil) return;
    
    // Current remote control is connected, disconnect first
    if (self.scrcpyBridge.running) {
        NSLog(@"> WaitQuit: Current scrcpy is running, send QUIT event");
        scrcpy_quit();
        [self.scrcpyBridge resetContext];
        [self performSelector:@selector(autoConnect) withObject:nil afterDelay:1.f];
        return;
    }
    
    // Wait for current view is actived
    if (self.view.window != nil && self.view.window.isKeyWindow == NO) {
        NSLog(@"> WaitQuit: self.view.window is not keyWindow");
        [self performSelector:@selector(autoConnect) withObject:nil afterDelay:1.f];
        return;
    }
    
    // Parse URL params
    [SchemeHandler URLToScrcpyParams:ScrcpyParams.sharedParams.autoConnectURL];
    ScrcpyParams.sharedParams.autoConnectURL = nil;
    
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
    return self.bitRate.text;
}

-(void)setBitRateText:(NSString *)bitRateText {
    NSInteger bitRateNum = [[bitRateText stringByReplacingOccurrencesOfString:@"M" withString:@""] integerValue];
    [self setBitRateValue:bitRateNum];
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
    self.bitRateUpper.enabled = enabled;
    self.bitRateLower.enabled = enabled;
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
    if (ScrcpyParams.sharedParams.adbSerial.isValid) {
        [scrcpyOptions addObjectsFromArray:@[ @"-s", ScrcpyParams.sharedParams.adbSerial ]];
    }
    
    // Add maxSize option
    if (ScrcpyParams.sharedParams.maxSize.isValid) {
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
