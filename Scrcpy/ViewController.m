//
//  ViewController.m
//  Scrcpy
//
//  Created by Ethan on 2021/7/7.
//

#import "ViewController.h"
#import <SDL2/SDL.h>
int scrcpy_main(int argc, char *argv[]);

@interface ViewController ()
@property (nonatomic, strong)   UIButton    *connectButton;
@property (nonatomic, strong)   UITableView *formView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupViews];
}

- (void)setupViews {
    self.title = @"Scrcpy";
    self.view.backgroundColor = UIColor.whiteColor;

    // Custom navigationBar
    UINavigationBarAppearance* navBarAppearance = [self.navigationController.navigationBar standardAppearance];
    [navBarAppearance configureWithOpaqueBackground];
    navBarAppearance.titleTextAttributes = @{NSForegroundColorAttributeName: UIColor.whiteColor};
    navBarAppearance.largeTitleTextAttributes = @{NSForegroundColorAttributeName: UIColor.whiteColor};
    navBarAppearance.backgroundColor = [UIColor colorWithRed:0x44/256.f
                                                       green:0x63/256.f
                                                        blue:0x3F/256.f
                                                       alpha:1.f];
    self.navigationController.navigationBar.standardAppearance = navBarAppearance;
    self.navigationController.navigationBar.scrollEdgeAppearance = navBarAppearance;
    
    // Connect button
    [self.view addSubview:self.connectButton];
    [self.connectButton addTarget:self action:@selector(startScrcpy) forControlEvents:(UIControlEventTouchUpInside)];
    self.connectButton.frame = CGRectMake(0, 0, self.view.bounds.size.width - 60, 50);
    self.connectButton.center = self.view.center;
    
    [self setNeedsStatusBarAppearanceUpdate];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - Actions

- (void)startScrcpy {
    // Because after SDL proxied didFinishLauch, PumpEvent will set to FASLE
    // So we need to set to TRUE in order to handle UI events
    SDL_iPhoneSetEventPump(SDL_TRUE);
    [self performSelector:@selector(scrcpyMain) withObject:nil afterDelay:0];
    
    // Show indicator animation
    self.connectButton.enabled = NO;
}

- (void)scrcpyMain {
    char *scrcpy_argv[4] = { "scrcpy", "-V", "debug", "-f" };
    scrcpy_main(4, scrcpy_argv);
}

#pragma mark - Getters

- (UIButton *)connectButton {
    if (_connectButton) {
        return _connectButton;
    }
    
    _connectButton = [[UIButton alloc] initWithFrame:(CGRectZero)];
    [_connectButton setTitle:@"Connect" forState:(UIControlStateNormal)];
    [_connectButton setTitleColor:UIColor.whiteColor forState:(UIControlStateNormal)];
    [_connectButton setTitleColor:[UIColor colorWithWhite:1 alpha:0.5] forState:(UIControlStateHighlighted)];
    [_connectButton setTitleColor:[UIColor colorWithWhite:1 alpha:0.5] forState:(UIControlStateDisabled)];
    _connectButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    _connectButton.backgroundColor = [UIColor colorWithRed:151/255.f green:192/255.f blue:36/255.f alpha:1.0f];
    _connectButton.layer.cornerRadius = 10.f;
    
    return _connectButton;
}

- (UITableView *)formView {
    if (_formView) {
        return _formView;
    }
    
    _formView = [[UITableView alloc] initWithFrame:(CGRectZero)];
    _formView.delegate = (id<UITableViewDelegate>)self;
    _formView.dataSource = (id<UITableViewDataSource>)self;
    
    return _formView;
}

@end
