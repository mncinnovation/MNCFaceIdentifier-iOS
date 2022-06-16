//
//  MFIUtils.h
//  MNCFaceIdentifier
//
//  Created by MCOMM00008 on 30/05/22.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreVideo/CoreVideo.h>
#import <UIKit/UIKit.h>
#import "MFIComparationModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface MFIUtils : NSObject

+ (UIImageOrientation)imageOrientationFromDevicePosition:(AVCaptureDevicePosition)devicePosition;
+ (UIDeviceOrientation)currentUIOrientation;
+ (void)addDotFace:(CGRect)faceRect toView:(UIView *)view;
+ (void)addDot:(CGRect)dotRect toView:(UIView *)view withColor:(UIColor *)color;
+ (MFIComparationModel *)getRectAccuration:(CGRect)mainRect byComparison:(CGRect)viewRect enableDot:(BOOL)isDotEnable viewForDot:(UIView *)dotView;
+ (NSString *)saveImageToStorage:(UIImage *)image withFileName:(NSString *)filename;

@end

NS_ASSUME_NONNULL_END
