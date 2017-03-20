//
//  HYDecoder.h
//  EFB
//
//  Created by Sunhy on 16/3/5.
//  Copyright © 2016年 Buaa. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Aircraft;

@interface HYDecoder : NSObject

/** aircraftsArray所有的对aircraftsArray进行的并发写操作都应该在这个队列上进行*/
@property (nonatomic, strong) dispatch_queue_t concurrenAircraftsArrayQueue;
@property (nonatomic) int usedPackets;
@property (nonatomic, strong) NSDate *timeOfAnyUpadate;
/** data time. receive time of date in realtime or time from save file on replay*/ 
@property (nonatomic, strong) NSDate *dataTime;
@property (nonatomic, strong) NSDate *lastDataTime;

- (void)decodeMutiADSBMessageWithData:(NSData *)data;
- (void)checkOverTimeAircraftByTime;
- (void)clearAllData;
- (NSDictionary *)fetchData;

@end
