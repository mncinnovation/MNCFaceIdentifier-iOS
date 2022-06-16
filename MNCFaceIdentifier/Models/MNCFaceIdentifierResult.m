//
//  MNCFaceIdentifierResult.m
//  MNCFaceIdentifier
//
//  Created by MCOMM00008 on 30/05/22.
//

#import "MNCFaceIdentifierResult.h"

@implementation MNCFaceIdentifierResult

- (NSString *)asJson {
    NSError *writeError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[self dictionary] options:NSJSONWritingPrettyPrinted error:&writeError];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return jsonString;
}

- (NSDictionary *)dictionary {
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    NSMutableArray *arrayDictionary = [NSMutableArray new];
    
    for (MOIFaceModel *dick in _detectionResult) {
        [arrayDictionary addObject:dick.dictionary];
    }
    
    [dictionary setObject:(self.errorMessage == nil) ? [NSNull null] : self.errorMessage forKey:@"errorMessage"];
    [dictionary setObject:@(self.isSuccess)  forKey:@"isSuccess"];
    [dictionary setObject:@(self.attempt) forKey:@"attempt"];
    [dictionary setObject:@(self.totalTimeInMillis) forKey:@"totalTimeMillis"];
    [dictionary setObject:arrayDictionary forKey:@"detectionResult"];
    
    return [[NSDictionary alloc] initWithDictionary:dictionary copyItems:YES];
}

@end
