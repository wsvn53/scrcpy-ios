//
//  ViewController.m
//  Scrcpy
//
//  Created by Ethan on 2021/7/7.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupViews];
}

- (void)setupViews {
    self.title = @"Scrcpy";
    self.view.backgroundColor = UIColor.whiteColor;
}

@end
