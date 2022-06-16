//
//  MFIIdentifierViewController.h
//  MNCFaceIdentifier
//
//  Created by MCOMM00008 on 30/05/22.
//

#import <UIKit/UIKit.h>
#import "MNCFaceIdentifierDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface MFIIdentifierViewController : UIViewController

@property (nonatomic, weak) id <MNCFaceIdentifierDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
