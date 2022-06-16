//
//  MNCFaceIdentifierClient.m
//  MNCFaceIdentifier
//
//  Created by MCOMM00008 on 30/05/22.
//

#import "MNCFaceIdentifierClient.h"
#import "MFISplashScreenViewController.h"

@interface MNCFaceIdentifierClient()

@property (nonatomic, retain) MFISplashScreenViewController *splashScreenController;

@end

@implementation MNCFaceIdentifierClient: NSObject

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSBundle *bundle = [NSBundle bundleWithIdentifier:@"MNCIdentifier.MNCFaceIdentifier"];
        self.splashScreenController = [[MFISplashScreenViewController alloc] initWithNibName:nil bundle:bundle];
    }
    return self;
}

- (void)setDelegate:(id<MNCFaceIdentifierDelegate>)delegate{
    self.splashScreenController.delegate = delegate;
}

- (id<MNCFaceIdentifierDelegate>)delegate{
    return self.splashScreenController.delegate;
}

- (void)showFaceIdentifier:(UIViewController *)parent {
    self.splashScreenController.modalPresentationStyle = UIModalPresentationFullScreen;
    [parent presentViewController:self.splashScreenController animated:YES completion:nil];
}

@end
