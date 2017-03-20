//
//  NSMutableArray+SimpleQueue.h
//  EFB
//
//  Created by Sunhy on 16/7/5.
//  Copyright © 2016年 Buaa. All rights reserved.
//

#import <Foundation/Foundation.h>

#define EFB_QUEUE_MAX_SIZE 200
@interface NSMutableArray (EFBSimpleQueue)

- (id)efb_dequeue;
- (void)efb_enqueue:(id)obj;

@end
