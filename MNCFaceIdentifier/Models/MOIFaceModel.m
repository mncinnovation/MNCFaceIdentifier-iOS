//
//  MOIFaceModel.m
//  MNCFaceIdentifier
//
//  Created by MCOMM00008 on 15/06/22.
//

#import "MOIFaceModel.h"

@implementation MOIFaceModel

- (NSDictionary *)dictionary {
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    [dictionary setObject:[self formatDetectionModeToString] forKey:@"detectionMode"];
    [dictionary setObject:self.image forKey:@"image"];
    [dictionary setObject:@(self.timeMillis) forKey:@"timeMillis"];
    
    return [[NSDictionary alloc] initWithDictionary:dictionary copyItems:YES];
}

- (NSString *)formatDetectionModeToString {
    NSString *result = nil;
    
    switch (self.detectionMode) {
        case HOLD_STILL:
            result = @"HOLD_STILL";
            break;
        case OPEN_MOUTH:
            result = @"OPEN_MOUTH";
            break;
        case BLINK:
            result = @"BLINK";
            break;
        case SHAKE_HEAD:
            result = @"SHAKE_HEAD";
            break;
        case SMILE:
            result = @"SMILE";
            break;
    }
    
    return result;
}

@end
