//
//  ScrcpyViewController.m
//  Scrcpy
//
//  Created by Ethan on 2021/7/9.
//

#import "ScrcpyViewController.h"
#import <SDL2/SDL.h>

#define   kSDLDidCreateRendererNotification   @"kSDLDidCreateRendererNotification"
int scrcpy_main(int argc, char *argv[]);

@interface ScrcpyViewController ()
@property (weak, nonatomic) IBOutlet UIButton *connectButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicatorView;

@end

@implementation ScrcpyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupViews];
    
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
    navBarAppearance.backgroundColor = [UIColor colorWithRed:0x33/255.f
                                                       green:0x99/255.f
                                                        blue:0x33/255.f
                                                       alpha:1.0f];;
    self.navigationController.navigationBar.standardAppearance = navBarAppearance;
    self.navigationController.navigationBar.scrollEdgeAppearance = navBarAppearance;
    
    // IndicatorView
    [self.indicatorView stopAnimating];
}

#pragma mark - Actions

- (IBAction)startScrcpy:(id)sender {
    // Show indicator animation
    self.connectButton.enabled = NO;
    [self.indicatorView startAnimating];
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, NO);
    
    // Because after SDL proxied didFinishLauch, PumpEvent will set to FASLE
    // So we need to set to TRUE in order to handle UI events
    SDL_iPhoneSetEventPump(SDL_TRUE);
    [self performSelector:@selector(scrcpyMain) withObject:nil afterDelay:0];
}

- (void)scrcpyMain {
    char *scrcpy_argv[4] = { "scrcpy", "-V", "debug", "-f" };
    scrcpy_main(4, scrcpy_argv);
    NSLog(@"Scrcpy STOPPED.");
}

- (void)resetViews {
    self.connectButton.enabled = YES;
    [self.indicatorView stopAnimating];
}

@end
