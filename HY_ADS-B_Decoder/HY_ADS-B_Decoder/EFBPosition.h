//
//  EFBPosition.h
//  EFB
//
//  Created by Sunhy on 16/6/30.
//  Copyright © 2016年 Buaa. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EFBPosition : NSObject

/** degree lon*/ 
@property (nonatomic, assign) double lon;
@property (nonatomic, assign) double lat;
/** 记录收到位置的时间，距离1970年的时间(s)*/
@property (nonatomic, assign) NSTimeInterval recevieTime;
@property (nonatomic, assign) BOOL isValid;

- (instancetype)initWithLon:(double)lon andLat:(double)lat;

@end
