//
//  MOIFaceModel.h
//  MNCFaceIdentifier
//
//  Created by MCOMM00008 on 15/06/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum DetectionMode {
    HOLD_STILL,
    OPEN_MOUTH,
    BLINK,
    SHAKE_HEAD,
    SMILE
} DetectionMode;

@interface MOIFaceModel : NSObject

@property (nonatomic) DetectionMode detectionMode;
@property (nonatomic) NSString* image;
@property (nonatomic) long timeMillis;

- (NSDictionary *)dictionary;


@end

NS_ASSUME_NONNULL_END
