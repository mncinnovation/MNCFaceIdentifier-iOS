//
//  MFIDataModel.h
//  MNCFaceIdentifier
//
//  Created by MCOMM00008 on 30/05/22.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MFIDataModel : NSObject

@property (nonatomic) CGFloat rotX;
@property (nonatomic) CGFloat rotY;
@property (nonatomic) CGFloat rotZ;
@property (nonatomic) CGFloat smileProb;
@property (nonatomic) CGFloat leftEyeProb;
@property (nonatomic) CGFloat rightEyeProb;
@property (nonatomic) BOOL hasBlink;
@property (nonatomic) BOOL hasLookRight;
@property (nonatomic) BOOL hasLookLeft;
@property (nonatomic) BOOL hasSmile;

- (void)blinkingCheck;
- (void)lookDirectionCheck;
- (void)smilingCheck;

@end

NS_ASSUME_NONNULL_END
