//
//  MFISplashScreenViewController.m
//  MNCFaceIdentifier
//
//  Created by MCOMM00008 on 30/05/22.
//

#import "MFISplashScreenViewController.h"
#import "MFIIdentifierViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface MFISplashScreenViewController () {
    NSBundle *bundle;
}

@property (nonatomic, retain) MFIIdentifierViewController *identifierController;

@end

@implementation MFISplashScreenViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        bundle = [NSBundle bundleWithIdentifier:@"MNCIdentifier.MNCFaceIdentifier"];
        self.identifierController = [[MFIIdentifierViewController alloc] initWithNibName:nil bundle:bundle];
    }
    return self;
}

- (void)setDelegate:(id<MNCFaceIdentifierDelegate>)delegate {
    self.identifierController.delegate = delegate;
}

- (id<MNCFaceIdentifierDelegate>)delegate{
    return self.identifierController.delegate;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[self navigationController] setNavigationBarHidden:YES animated:NO];
    [self setupView];
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkPermissionVideo) userInfo:nil repeats:NO];
}

- (void)setupView{
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIImage *contentImage = [UIImage imageNamed:@"icon_logo" inBundle:bundle compatibleWithTraitCollection:nil];
    UIImageView *contentImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, width, width)];
    contentImageView.image = contentImage;
    
    UILabel *contentLabel = [[UILabel alloc] init];
    contentLabel.text = @"Face Recognition";
    
    [contentLabel setFont:[UIFont boldSystemFontOfSize:36]];
    
    UIStackView *contentStackView = [[UIStackView alloc] init];
    
    contentStackView.axis = UILayoutConstraintAxisVertical;
    contentStackView.distribution = UIStackViewDistributionEqualSpacing;
    contentStackView.alignment = UIStackViewAlignmentCenter;
    contentStackView.spacing = 20;
    
    [contentStackView addArrangedSubview:contentImageView];
    [contentStackView addArrangedSubview:contentLabel];
    
    contentStackView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:contentStackView];
    
    [contentStackView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
    [contentStackView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor].active = YES;
    
    UILabel *footerLabel = [[UILabel alloc] init];
    footerLabel.text = @"Developed by : ";
    [footerLabel setFont:[UIFont systemFontOfSize:12]];
    
    UIImage *footerImage = [UIImage imageNamed:@"icon_innocent" inBundle:bundle compatibleWithTraitCollection:nil];
    UIImageView *footerImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 64, 24)];
    footerImageView.image = footerImage;
    
    UIStackView *footerStackView = [[UIStackView alloc] init];
    
    footerStackView.axis = UILayoutConstraintAxisHorizontal;
    footerStackView.alignment = UIStackViewAlignmentCenter;
    footerStackView.distribution = UIStackViewDistributionEqualSpacing;
    footerStackView.spacing = 0;
    
    [footerStackView addArrangedSubview:footerLabel];
    [footerStackView addArrangedSubview:footerImageView];
    
    footerStackView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:footerStackView];
    
    [footerStackView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-24].active = YES;
    [footerStackView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
}

- (void)checkPermissionVideo {
    switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
        case AVAuthorizationStatusNotDetermined:
            [self requestCaptureDeviceVideoPermission];
            break;
        case AVAuthorizationStatusRestricted:
            [self errorResult];
            break;
        case AVAuthorizationStatusDenied:
            [self errorResult];
            break;
        case AVAuthorizationStatusAuthorized:
            [self goToIdentifier];
            break;
    }
}

- (void)requestCaptureDeviceVideoPermission {
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        if (granted) {
            [self goToIdentifier];
        } else {
            [self errorResult];
        }
    }];
}

- (void)errorResult {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"Camera permission not granted, please allow from your settings" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *closeButton = [UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            MNCFaceIdentifierResult *result = [MNCFaceIdentifierResult new];
            result.isSuccess = NO;
            result.errorMessage = @"Camera permission not granted";
            
            [self.delegate faceIdentifierResult:result];
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
        
        [alert addAction:closeButton];
         
        [self presentViewController:alert animated:YES completion:nil];
        
    });
}

- (void)goToIdentifier {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.identifierController.modalPresentationStyle = UIModalPresentationFullScreen;
        UIViewController *currentViewController = [self presentingViewController];
        
        [self dismissViewControllerAnimated:YES completion:^{
            [currentViewController presentViewController:self.identifierController animated:YES completion:nil];
        }];
    });
}

@end
