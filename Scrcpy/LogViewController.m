//
//  LogViewController.m
//  Scrcpy
//
//  Created by Ethan on 2022/1/4.
//

#import "LogViewController.h"

NSString *NSLogCurrent(void) {
    NSString *logRoot = [NSTemporaryDirectory() stringByAppendingString:@"Logs"];
    if ([NSFileManager.defaultManager fileExistsAtPath:logRoot] == NO) {
        [NSFileManager.defaultManager createDirectoryAtPath:logRoot
                                withIntermediateDirectories:YES
                                                 attributes:nil
                                                      error:nil];
    }
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd"];
    NSString *nowDate = [dateFormat stringFromDate:NSDate.date];
    return [NSString stringWithFormat:@"%@/Scrcpy-%@.log", logRoot, nowDate];
}

void NSLogSave(NSString *logText) {
    static NSFileHandle *logFile = nil;
    if (logFile == nil) {
        NSString *logPath = NSLogCurrent();
        
        // Create file if not exists
        if ([NSFileManager.defaultManager fileExistsAtPath:logPath] == NO) {
            [NSFileManager.defaultManager createFileAtPath:logPath contents:NSData.data attributes:nil];
        }
        
        logFile = [NSFileHandle fileHandleForWritingAtPath:logPath];
        [logFile truncateFileAtOffset:[logFile seekToEndOfFile]];
    }
    
    NSError *error;
    [logFile writeData:[[logText stringByAppendingString:@"\n"] dataUsingEncoding:NSUTF8StringEncoding] error:&error];
    
    if (error != nil) {
        NSLogv([NSString stringWithFormat:@"> Save Log: %@", error.description], NULL);
    }
}

NSString *NSLogLoad(void) {
    return [[NSString alloc] initWithData:[NSData dataWithContentsOfFile:NSLogCurrent()] encoding:NSUTF8StringEncoding];
}

// Handle NSLog outputs rewrite to local file
void NSLog(NSString *format, ...) {
    va_list args;
    va_start(args, format);
    NSLogv(format, args);
    NSLogSave([[NSString alloc] initWithFormat:format arguments:args]);
    va_end(args);
}

@interface LogViewController ()
@end

@implementation LogViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupViews];
}

- (void)setupViews {
    self.view.backgroundColor = UIColor.whiteColor;
    
    UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[ ({
        UIView *spaceView = [[UIView alloc] initWithFrame:CGRectZero];
        spaceView;
    }), ({
        UIStackView *headerStack = [[UIStackView alloc] initWithArrangedSubviews:@[({
            UILabel *titleLabel = [[UILabel alloc] initWithFrame:(CGRectZero)];
            titleLabel.text = @" Scrcpy Logs:";
            titleLabel.textColor = UIColor.blackColor;
            titleLabel.font = [UIFont boldSystemFontOfSize:16.f];
            titleLabel;
        }), ({
            UIButton *closeButton = [UIButton buttonWithType:(UIButtonTypeClose)];
            [closeButton addTarget:self action:@selector(dismissLogs) forControlEvents:UIControlEventTouchUpInside];
            closeButton;
        })]];
        headerStack.axis = UILayoutConstraintAxisHorizontal;
        headerStack;
    }), ({
        UITextView *textView = [[UITextView alloc] initWithFrame:(CGRectZero)];
        textView.textColor = UIColor.blackColor;
        textView.font = [UIFont systemFontOfSize:14.f];
        textView.editable = NO;
        textView.selectable = YES;
        textView.text = NSLogLoad();
        textView;
    }),
    ]];
    [self.view addSubview:stackView];
    
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.spacing = 15;
    
    [[stackView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor] setActive:YES];
    [[stackView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor] setActive:YES];
    [[stackView.widthAnchor constraintEqualToAnchor:self.view.widthAnchor constant:-20] setActive:YES];
    [[stackView.heightAnchor constraintEqualToAnchor:self.view.heightAnchor] setActive:YES];
}

- (void)dismissLogs {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
