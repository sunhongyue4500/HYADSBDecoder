//
//  NSMutableArray+SimpleQueue.m
//  EFB
//
//  Created by Sunhy on 16/7/5.
//  Copyright © 2016年 Buaa. All rights reserved.
//

#import "NSMutableArray+EFBSimpleQueue.h"

@implementation NSMutableArray (EFBSimpleQueue)

- (id)efb_dequeue {
    id obj = [self objectAtIndex:0];
    [self removeObjectAtIndex:0];
    return obj;
}

- (void)efb_enqueue:(id)obj {
    if (self.count >= EFB_QUEUE_MAX_SIZE) {
        [self efb_dequeue];
        [self addObject:obj];
    } else {
        [self addObject:obj];
    }
}

@end
