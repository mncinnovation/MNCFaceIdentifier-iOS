//
//  MFIDataModel.m
//  MNCFaceIdentifier
//
//  Created by MCOMM00008 on 30/05/22.
//

#import "MFIDataModel.h"

@implementation MFIDataModel

- (void)blinkingCheck {
    if (_leftEyeProb < 0.2 && _rightEyeProb < 0.2) {
        _hasBlink = true;
    }
}

- (void)lookDirectionCheck {
    if (_rotY < -30) {
        _hasLookLeft = true;
    }
    
    if (_rotY > 30) {
        _hasLookRight = true;
    }
}

- (void)smilingCheck {
    if (_smileProb > 0.8) {
        _hasSmile = true;
    }
}

@end
