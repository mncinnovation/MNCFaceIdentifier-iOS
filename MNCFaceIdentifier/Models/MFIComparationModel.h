//
//  MFIComparationModel.h
//  MNCFaceIdentifier
//
//  Created by MCOMM00008 on 30/05/22.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MFIComparationModel : NSObject

@property (nonatomic) CGFloat leftPercentage;
@property (nonatomic) CGFloat rightPercentage;
@property (nonatomic) CGFloat topPercentage;
@property (nonatomic) CGFloat bottomPercentage;
@property (nonatomic) CGFloat accuratePercentage;
@property (nonatomic) BOOL isLeftPointInside;
@property (nonatomic) BOOL isRightPointInside;
@property (nonatomic) BOOL isTopPointInside;
@property (nonatomic) BOOL isBottomPointInside;

@end

NS_ASSUME_NONNULL_END
