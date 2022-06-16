//
//  MFIUtils.m
//  MNCFaceIdentifier
//
//  Created by MCOMM00008 on 30/05/22.
//

#import "MFIUtils.h"

@implementation MFIUtils

+ (UIImageOrientation)imageOrientationFromDevicePosition:(AVCaptureDevicePosition)devicePosition {
    UIDeviceOrientation deviceOrientation = UIDevice.currentDevice.orientation;
    if (deviceOrientation == UIDeviceOrientationFaceDown ||
        deviceOrientation == UIDeviceOrientationFaceUp ||
        deviceOrientation == UIDeviceOrientationUnknown) {
        deviceOrientation = [self currentUIOrientation];
    }
    switch (deviceOrientation) {
        case UIDeviceOrientationPortrait:
            return devicePosition == AVCaptureDevicePositionFront ? UIImageOrientationLeftMirrored
            : UIImageOrientationRight;
        case UIDeviceOrientationLandscapeLeft:
            return devicePosition == AVCaptureDevicePositionFront ? UIImageOrientationDownMirrored
            : UIImageOrientationUp;
        case UIDeviceOrientationPortraitUpsideDown:
            return devicePosition == AVCaptureDevicePositionFront ? UIImageOrientationRightMirrored
            : UIImageOrientationLeft;
        case UIDeviceOrientationLandscapeRight:
            return devicePosition == AVCaptureDevicePositionFront ? UIImageOrientationUpMirrored
            : UIImageOrientationDown;
        case UIDeviceOrientationFaceDown:
        case UIDeviceOrientationFaceUp:
        case UIDeviceOrientationUnknown:
            return UIImageOrientationUp;
    }
}

+ (UIDeviceOrientation)currentUIOrientation {
    UIDeviceOrientation (^deviceOrientation)(void) = ^UIDeviceOrientation(void) {
        switch (UIApplication.sharedApplication.statusBarOrientation) {
            case UIInterfaceOrientationLandscapeLeft:
                return UIDeviceOrientationLandscapeRight;
            case UIInterfaceOrientationLandscapeRight:
                return UIDeviceOrientationLandscapeLeft;
            case UIInterfaceOrientationPortraitUpsideDown:
                return UIDeviceOrientationPortraitUpsideDown;
            case UIInterfaceOrientationPortrait:
            case UIInterfaceOrientationUnknown:
                return UIDeviceOrientationPortrait;
        }
    };
    
    if (NSThread.isMainThread) {
        return deviceOrientation();
    } else {
        __block UIDeviceOrientation currentOrientation = UIDeviceOrientationPortrait;
        dispatch_sync(dispatch_get_main_queue(), ^{
            currentOrientation = deviceOrientation();
        });
        return currentOrientation;
    }
}

+ (void)addDotFace:(CGRect)faceRect toView:(UIView *)view {
    CGFloat faceCenterX = (faceRect.size.width / 2) + faceRect.origin.x;
    CGFloat faceCenterY = (faceRect.size.height / 2) + faceRect.origin.y;
    
    UIView *centerTopView = [[UIView alloc] initWithFrame:CGRectMake(faceCenterX, faceRect.origin.y, 6, 6)];
    centerTopView.layer.cornerRadius = 3;
    centerTopView.backgroundColor = UIColor.redColor;
    [view addSubview:centerTopView];
    
    UIView *centerBottomView = [[UIView alloc] initWithFrame:CGRectMake(faceCenterX, faceRect.origin.y + faceRect.size.height, 6, 6)];
    centerBottomView.layer.cornerRadius = 3;
    centerBottomView.backgroundColor = UIColor.redColor;
    [view addSubview:centerBottomView];
    
    UIView *leftCenterView = [[UIView alloc] initWithFrame:CGRectMake(faceRect.origin.x, faceCenterY, 6, 6)];
    leftCenterView.layer.cornerRadius = 3;
    leftCenterView.backgroundColor = UIColor.redColor;
    [view addSubview:leftCenterView];
    
    UIView *rightCenterView = [[UIView alloc] initWithFrame:CGRectMake(faceRect.origin.x + faceRect.size.width, faceCenterY, 6, 6)];
    rightCenterView.layer.cornerRadius = 3;
    rightCenterView.backgroundColor = UIColor.redColor;
    [view addSubview:rightCenterView];
}

+ (void)addDot:(CGRect)dotRect toView:(UIView *)view withColor:(UIColor *)color {
    CGRect rect = CGRectMake(dotRect.origin.x, dotRect.origin.y, 6, 6);
    UIView *dotView = [[UIView alloc] initWithFrame:rect];
    dotView.layer.cornerRadius = 3;
    dotView.backgroundColor = color;
    [view addSubview:dotView];
}

+ (MFIComparationModel *)getRectAccuration:(CGRect)mainRect byComparison:(CGRect)viewRect enableDot:(BOOL)isDotEnable viewForDot:(UIView *)dotView{
    CGRect viewTopLeftRect = CGRectMake(viewRect.origin.x, viewRect.origin.y, 0, 0);
    CGRect viewTopRightRect = CGRectMake(viewTopLeftRect.origin.x + viewRect.size.width, viewTopLeftRect.origin.y, 0, 0);
    CGRect viewBottomLeftRect = CGRectMake(viewTopLeftRect.origin.x, viewTopLeftRect.origin.y + viewRect.size.height, 0, 0);
    CGRect viewBottomRightRect = CGRectMake(viewTopRightRect.origin.x, viewBottomLeftRect.origin.y, 0, 0);
    
    CGFloat mainCenterX = (mainRect.size.width / 2) + mainRect.origin.x;
    CGFloat mainCenterY = (mainRect.size.height / 2) + mainRect.origin.y;
    
    CGRect mainCenterLeft = CGRectMake(mainRect.origin.x, mainCenterY, 0, 0);
    CGRect mainCenterRight = CGRectMake(mainCenterLeft.origin.x + mainRect.size.width, mainCenterY, 0, 0);
    CGRect mainCenterTop = CGRectMake(mainCenterX, mainRect.origin.y, 0, 0);
    CGRect mainCenterBottom = CGRectMake(mainCenterTop.origin.x, mainCenterTop.origin.y + mainRect.size.height, 0, 0);
    
    if (isDotEnable && dotView != nil) {
        [MFIUtils addDot:viewTopLeftRect toView:dotView withColor:UIColor.purpleColor];
        [MFIUtils addDot:viewTopRightRect toView:dotView withColor:UIColor.purpleColor];
        [MFIUtils addDot:viewBottomLeftRect toView:dotView withColor:UIColor.purpleColor];
        [MFIUtils addDot:viewBottomRightRect toView:dotView withColor:UIColor.purpleColor];
        
        [MFIUtils addDot:mainCenterLeft toView:dotView withColor:UIColor.redColor];
        [MFIUtils addDot:mainCenterRight toView:dotView withColor:UIColor.redColor];
        [MFIUtils addDot:mainCenterTop toView:dotView withColor:UIColor.blueColor];
        [MFIUtils addDot:mainCenterBottom toView:dotView withColor:UIColor.blueColor];
    }
    
    CGFloat leftPointDiff = mainCenterLeft.origin.x - viewTopLeftRect.origin.x;
    CGFloat rightPointDiff = mainCenterRight.origin.x - viewTopRightRect.origin.x;
    CGFloat topPointDiff = mainCenterTop.origin.y - viewTopLeftRect.origin.y;
    CGFloat bottomPointDiff = mainCenterBottom.origin.y - viewBottomLeftRect.origin.y;
    
    leftPointDiff = leftPointDiff < 0 ? leftPointDiff * -1 : leftPointDiff;
    rightPointDiff = rightPointDiff < 0 ? rightPointDiff * -1 : rightPointDiff;
    topPointDiff = topPointDiff < 0 ? topPointDiff * -1 : topPointDiff;
    bottomPointDiff = bottomPointDiff < 0 ? bottomPointDiff * -1 : bottomPointDiff;
    
    CGFloat leftPercentage = ((100 - leftPointDiff) / 100) * 100;
    CGFloat rightPercentage = ((100 - rightPointDiff) / 100) * 100;
    CGFloat topPercentage = ((100 - topPointDiff) / 100) * 100;
    CGFloat bottomPercentage = ((100 - bottomPointDiff) / 100) * 100;
    CGFloat accuratePercentage = (((leftPercentage + rightPercentage + topPercentage + bottomPercentage) /4) /100) * 100;
    
    BOOL isLeftPointInside = (mainCenterLeft.origin.x > viewTopLeftRect.origin.x && mainCenterLeft.origin.x < viewTopRightRect.origin.x && mainCenterLeft.origin.y > viewTopLeftRect.origin.y && mainCenterLeft.origin.y < viewBottomLeftRect.origin.y);
    BOOL isRightPointInside = (mainCenterRight.origin.x > viewTopLeftRect.origin.x && mainCenterRight.origin.x < viewTopRightRect.origin.x && mainCenterLeft.origin.x && mainCenterRight.origin.y > viewTopRightRect.origin.y &&  mainCenterRight.origin.y < viewBottomRightRect.origin.y);
    BOOL isTopPointInside = (mainCenterTop.origin.x > viewTopLeftRect.origin.x && mainCenterTop.origin.x < viewTopRightRect.origin.x && mainCenterTop.origin.y > viewTopLeftRect.origin.y && mainCenterTop.origin.y < viewBottomLeftRect.origin.y );
    BOOL isBottomPointInside = (mainCenterBottom.origin.x > viewBottomLeftRect.origin.x && mainCenterBottom.origin.x < viewBottomRightRect.origin.x && mainCenterBottom.origin.y > viewTopLeftRect.origin.y && mainCenterBottom.origin.y < viewBottomLeftRect.origin.y);
    
    MFIComparationModel *comparation = [MFIComparationModel new];
    comparation.leftPercentage = leftPercentage;
    comparation.rightPercentage = rightPercentage;
    comparation.topPercentage = topPercentage;
    comparation.bottomPercentage = bottomPercentage;
    comparation.accuratePercentage = accuratePercentage;
    comparation.isLeftPointInside = isLeftPointInside;
    comparation.isRightPointInside = isRightPointInside;
    comparation.isTopPointInside = isTopPointInside;
    comparation.isBottomPointInside = isBottomPointInside;
    
    return comparation;
}

+ (NSString *)saveImageToStorage:(UIImage *)image withFileName:(NSString *)filename {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:filename];
    
    [UIImageJPEGRepresentation(image, 1) writeToFile:filePath atomically:YES];
    
    return filePath;
}


@end
