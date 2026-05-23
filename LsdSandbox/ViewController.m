#import "ViewController.h"
#import "LsdHelper.h"

@interface ViewController ()
@property (nonatomic, strong) UIButton *acquireButton;
@property (nonatomic, strong) UITextView *logTextView;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UILabel *statusLabel;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"lsd 沙箱权限";
    self.view.backgroundColor = [UIColor colorWithWhite:0.08 alpha:1.0];
    [self setupUI];
}

- (void)setupUI {
    // Button
    self.acquireButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.acquireButton setTitle:@"获取 lsd 沙箱权限 / CarrierBundles 写入权限" forState:UIControlStateNormal];
    self.acquireButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [self.acquireButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.acquireButton.backgroundColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:1.0];
    self.acquireButton.layer.cornerRadius = 12;
    self.acquireButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.acquireButton addTarget:self action:@selector(acquireButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.acquireButton];
    
    // Activity Indicator
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    self.activityIndicator.color = [UIColor whiteColor];
    self.activityIndicator.hidesWhenStopped = YES;
    self.activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.activityIndicator];
    
    // Log TextView
    self.logTextView = [[UITextView alloc] init];
    self.logTextView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:1.0];
    self.logTextView.textColor = [UIColor colorWithRed:0.3 green:1.0 blue:0.3 alpha:1.0];
    self.logTextView.font = [UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightRegular];
    self.logTextView.editable = NO;
    self.logTextView.text = @"";
    self.logTextView.translatesAutoresizingMaskIntoConstraints = NO;
    self.logTextView.layer.cornerRadius = 8;
    self.logTextView.layer.borderWidth = 1;
    self.logTextView.layer.borderColor = UIColor.darkGrayColor.CGColor;
    self.logTextView.textContainerInset = UIEdgeInsetsMake(10, 10, 10, 10);
    [self.view addSubview:self.logTextView];
    
    // Status Label
    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.text = @"就绪";
    self.statusLabel.font = [UIFont systemFontOfSize:13];
    self.statusLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1.0];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.statusLabel];
    
    // Layout
    [NSLayoutConstraint activateConstraints:@[
        [self.acquireButton.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:60],
        [self.acquireButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.acquireButton.widthAnchor constraintEqualToConstant:320],
        [self.acquireButton.heightAnchor constraintEqualToConstant:52],
        
        [self.activityIndicator.centerYAnchor constraintEqualToAnchor:self.acquireButton.centerYAnchor],
        [self.activityIndicator.leadingAnchor constraintEqualToAnchor:self.acquireButton.trailingAnchor constant:12],
        
        [self.logTextView.topAnchor constraintEqualToAnchor:self.acquireButton.bottomAnchor constant:30],
        [self.logTextView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.logTextView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [self.logTextView.bottomAnchor constraintEqualToAnchor:self.statusLabel.topAnchor constant:-10],
        
        [self.statusLabel.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-15],
        [self.statusLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    ]];
}

- (void)acquireButtonTapped {
    self.acquireButton.enabled = NO;
    [self.activityIndicator startAnimating];
    self.statusLabel.text = @"正在获取 lsd 沙箱权限...";
    self.statusLabel.textColor = [UIColor yellowColor];
    self.logTextView.text = @"[日志] 开始获取 lsd 沙箱权限...\n";
    
    __weak typeof(self) weakSelf = self;
    [LsdHelper acquirePermissionWithCompletion:^(BOOL success, NSString *log) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        
        strongSelf.acquireButton.enabled = YES;
        [strongSelf.activityIndicator stopAnimating];
        strongSelf.logTextView.text = log;
        
        if (success) {
            strongSelf.statusLabel.text = @"成功 - lsd 沙箱权限已获取，可编辑 CarrierBundles";
            strongSelf.statusLabel.textColor = [UIColor colorWithRed:0.3 green:1.0 blue:0.3 alpha:1.0];
            [strongSelf.acquireButton setTitle:@"已获取 lsd 沙箱权限" forState:UIControlStateNormal];
            strongSelf.acquireButton.backgroundColor = [UIColor colorWithRed:0.2 green:0.6 blue:0.2 alpha:1.0];
            
            [UIView animateWithDuration:0.2 animations:^{
                strongSelf.view.backgroundColor = [UIColor colorWithRed:0.0 green:0.2 blue:0.05 alpha:1.0];
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.5 animations:^{
                    strongSelf.view.backgroundColor = [UIColor colorWithWhite:0.08 alpha:1.0];
                }];
            }];
        } else {
            strongSelf.statusLabel.text = @"失败 - 请查看日志";
            strongSelf.statusLabel.textColor = [UIColor redColor];
        }
    }];
}

@end