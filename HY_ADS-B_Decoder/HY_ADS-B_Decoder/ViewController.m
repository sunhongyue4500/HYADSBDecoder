//
//  ViewController.m
//  HY_ADS-B_Decoder
//
//  Created by Sunhy on 17/3/20.
//  Copyright © 2017年 Sunhy. All rights reserved.
//

#import "ViewController.h"
#import "HYDecoder.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    HYDecoder *decode = [[HYDecoder alloc] init];
    // Fake data
    NSArray *array = @[@"*8D7806DE994555A3206490DA95C3;\r\n", @"*8D7806DE58A3660DC6DB909C0F0F;\r\n", @"*8D78041758B53600053275735DD9;\r\n", @"*8D7804179910A13740049484CB14;\r\n", @"*8D7803035897561B053740D6A094;\r\n", @"*8D780F5158A14653B68826698290;\r\n", @"*8D7BB0B4586592A384FA722727B5;\r\n", @"*8D780FCD994509AD60088A6B4A38;\r\n", @"*8D7BB0B499454A9740A88652F030;\r\n", @"*8D78041758B5360029327B6F86BD;\r\n", @"*8D7BB0B499454A9740A4861AAA30;\r\n", @"*8D78041758B542717FD8AC4CDA12;\r\n", @"*8D78030399409A34C8048BC99164;\r\n"];
    NSData *tempData = nil;
    for(NSString *str in array) {
        tempData = [str dataUsingEncoding:NSUTF8StringEncoding];
        [decode decodeMutiADSBMessageWithData:tempData];
    }
    NSDictionary *dic = [decode fetchData];
    NSLog(@"%@", dic);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
