//
//  EFBPosition.m
//  EFB
//
//  Created by Sunhy on 16/6/30.
//  Copyright © 2016年 Buaa. All rights reserved.
//

#import "EFBPosition.h"

#define VALUE_MIN_COMPARE 0.00001
@implementation EFBPosition

- (instancetype)init {
    if (self = [super init]) {
        _lon = -9999.;
        _lat = -9999.;
        _isValid = NO;
    }
    return self;
}

- (instancetype)initWithLon:(double)lon andLat:(double)lat {
    if (self = [super init]) {
        _lon = lon;
        _lat = lat;
        _isValid = YES;
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    EFBPosition *pos2 = object;
    if (self.isValid && pos2.isValid) {
        if (fabs(self.lon - pos2.lon) < VALUE_MIN_COMPARE && fabs(self.lat - pos2.lat) < VALUE_MIN_COMPARE) {
            return YES;
        }
    }
    return NO;
}

- (NSUInteger)hash {
    return [[NSString stringWithFormat:@"%.1f:%.1f:%.1f", _lon, _lat, _recevieTime] hash];
}

@end
