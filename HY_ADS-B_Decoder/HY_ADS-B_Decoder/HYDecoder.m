//
//  HYDecoder.m
//  EFB
//
//  Created by Sunhy on 16/3/5.
//  Copyright © 2016年 Buaa. All rights reserved.
//

#import "HYDecoder.h"
#import "Aircraft.h"
#import "Decoder.h"
#import "EFBPosition.h"
#import "NSMutableArray+EFBSimpleQueue.h"
/** 本类最好单例*/
@interface HYDecoder ()

/** save all decoded plane*/
@property (nonatomic, strong, readwrite) NSMutableDictionary *aircraftsArrayDic;

@end

// 保存每一条报文数据，共14个字节（112bit）,最后一个字节是同步用,raw data buffer (14 data, 1 sync)
unsigned char Dbuf[15];
//last dbuf
unsigned char DbufLast[15];
unsigned char Sbuf[32];

@implementation HYDecoder

- (instancetype)init{
    if (self = [super init]) {
        _aircraftsArrayDic = [[NSMutableDictionary alloc] init];
        _usedPackets = 0;
        _dataTime = nil;
        _lastDataTime = nil;
        _timeOfAnyUpadate = nil;
        //create a DISPATCH_QUEUE_CONCURRENT queue
        _concurrenAircraftsArrayQueue = dispatch_queue_create("come.mutuableArraySync.myqueue", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

/**
 *  return DF value and assign the Dbuf
 *
 *  @param data adsb data
 *
 *  @return DF value
 */
- (int)convert112AVRData:(NSData *)data
{
    int n;
    NSString *dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    char * myBuffer = (char *)malloc((int)[dataStr length] / 2 + 1);
    if (myBuffer == NULL) return -1;
    for (int i = 0; i < [dataStr length] - 1; i += 2) {
        unsigned int anInt;
        NSString * hexCharStr = [dataStr substringWithRange:NSMakeRange(i, 2)];
        NSScanner * scanner = [[NSScanner alloc] initWithString:hexCharStr];
        [scanner scanHexInt:&anInt];
        myBuffer[i / 2] = (char)anInt;
    }
    
    for(int k=0;k<dataStr.length;k++){
        Sbuf[k] = myBuffer[k];
    }
    free(myBuffer);
    myBuffer = NULL;
    for(n=0;n<14;n++){
        Dbuf[n] = Sbuf[n];
    }
    // 返回DF
    // 1----5
    // MSB-LSB
    return ((Dbuf[0])>>3)&0x1f;	/* df, isolated */
}

- (int)convert56PGRData:(NSData *)data
{
    int n;
    NSString *dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    char * myBuffer = (char *)malloc((int)[dataStr length] / 2 + 1);
    if (myBuffer == NULL) return -1;
    for (int i = 0; i < [dataStr length] - 1; i += 2) {
        unsigned int anInt;
        NSString * hexCharStr = [dataStr substringWithRange:NSMakeRange(i, 2)];
        NSScanner * scanner = [[NSScanner alloc] initWithString:hexCharStr];
        [scanner scanHexInt:&anInt];
        myBuffer[i / 2] = (char)anInt;
    }
    
    for(int k=0;k<dataStr.length;k++){
        Sbuf[k] = myBuffer[k];
    }
    free(myBuffer);
    myBuffer = NULL;
    for(n=0;n<14;n++){
        Dbuf[n] = Sbuf[n];
    }
    // 返回DF
    // 1----5
    // MSB-LSB
    return ((Dbuf[0])>>3)&0x1f;	/* df, isolated */
}

/*
 * ------------------------------------------------------------------------
 * fill structure 'AVel' from DF17 field ME with FTC19 pointed to by '*b'
 *
 * writes structure Plane *p members:
 * 	int verts
 *	double vert
 * 	double alt_d
 * 	double veast
 * 	double vnorth
 * 	double cogc
 * 	double sogc
 * 	double hdg
 * 	double tas
 * 	double ias
 *
 *
 * returns 0 on success
 *         1 on subtype error
 * ------------------------------------------------------------------------
 * */
- (int)aircraftVel:(unsigned char *)b withAircraft:(Aircraft *)aircraft
{
    int m,n;
    int subt;				/* ftc subtype */
    unsigned long int l;
    double sf;				/* scale factor */
    double x;
    
    //读取ME字段的 Subtype  ME 6-8
    subt = *b&0x7;			/* subtype 1..4 (bits 6..8) */
    if ((subt > 4) || (subt <= 0)) return 1;     //subType 不合法则返回1

    /* some flags */
    //垂直速度源 和ME的第36与，取得垂直速度源
    if ((*(b+4)&0x10) != 0) aircraft.verticalSpeedSource = 1; /* vertical speed source (bit 36) */
    
    /* vertical rate (in sign magnitude) to ft/min */
    //获取垂直速率
    l = *(b+4)<<8;
    l |= *(b+5);
    l >>= 2;
    l &= 0x1ff;
    if (l != 0)
    {
        aircraft.verticalSpeed = (double)((l-1)*64);		/* rate in ft/min */
        if ((*(b+4)&0x8) != 0) aircraft.verticalSpeed = -aircraft.verticalSpeed; /* if sign flag set */
    }
    
    /* altitude difference */
    //大气压高度差
    m = *(b+6)&0x7f;			/* GNSS-BARO (bits 49..56) */
    if (m != 0)
    {
        m -=1;
        aircraft.altDiffGNSSHeight = (double)m * 25.;
        //ME 第49位 大气压高度差符号
        if (*(b+6)&0x80) aircraft.altDiffGNSSHeight = -aircraft.altDiffGNSSHeight;
    }
    
    /* find scale factor for speed */
    sf = 1.;
    if ((subt == 2) || (subt == 4)) sf=4.;
    
    /* subtype 1 or 2 (ground speed components) */
    //1 2 为地面上方普通速度，即地面速度
    if (subt < 3)
    {
        /* speed components */
        //东西向标志位
        m = (*(b+1)&0x3)<<8;		/* east/west (bits 14..24)*/
        m |= *(b+2);
        n = (*(b+4)&0xe0)>>5;		/* north/south (bits 25..35)*/
        n |= (*(b+3)&0x7f)<<3;
        /* compute only if valid */
        //计算有效的东/西 南/北速度
        if ((m!=0) && (n!=0))
        {
            aircraft.speedOverGroundInEast = (double)(m-1)*sf;
            if ( (*(b+1)&0x4) != 0 ) aircraft.speedOverGroundInEast = -aircraft.speedOverGroundInEast;
            
            aircraft.speedOverGroundInNorth = (double)(n-1)*sf;
            if ( (*(b+3)&0x80) != 0 ) aircraft.speedOverGroundInNorth = -aircraft.speedOverGroundInNorth;
            
            /* computed heading and airspeed */
            aircraft.courseOverGround = -atan2(aircraft.speedOverGroundInNorth,aircraft.speedOverGroundInEast)*180./M_PI + 90.;
            if (aircraft.courseOverGround < 0.) aircraft.courseOverGround += 360.; /* angle to course */
            
            aircraft.speedOverGroundInKN = sqrt(pow(aircraft.speedOverGroundInEast,2)+pow(aircraft.speedOverGroundInNorth,2));
        }
    }
    /* subtype 3 and 4 (heading and airspeed)
     * 空速和航向信息
     */
    else
    {
        /* heading */
        if ((*(b+1)&4) != 0)		/* heading avail. (bit 14)*/
        {
            /* magnetic heading (bits 15..24) */
            m = *(b+2);
            m |= (*(b+1)&0x3)<<8;
            aircraft.heading = (double)m*360./1024.;
        }
        
        /* airspeed */		 
        m = (*(b+3)&0x7f)<<3;		/* speed (bits 26..35) */
        m |= (*(b+4)&0xe0)>>5;
        if (m != 0)
        {
            x = (double)(m-1)*sf;
            /* 1=TAS, 0=IAS (bit 25) */
            if ((*(b+3)&0x80) != 0)
                aircraft.tas = x;
            else
                aircraft.airSpeedIndicated = x;
        }
    }
    return 0;
}


- (double)GTRKHDG:(unsigned char *)b
{
    unsigned long int dd;
    dd = *(b+1);
    dd <<= 8;
    dd |= *(b+2);
    dd >>= 4;
    if (dd&0x80)
    {
        return -9999.;		/* 'unknown' value */
    }
    return (double)(dd&0x7f)*360./128.0;
}

#pragma mark - **************** Decode
- (void)checkOverTimeAircraftByTime{
    // 120s超时时间，150s没收到就标记飞机为无效信息飞机
    [self markOvertimeAircraftByTime:[[NSDate date] timeIntervalSince1970] - 120 andNeed2DeleteAircraft:[[NSDate date] timeIntervalSince1970] - 150];
}

/**
 *  mark overtime aircraft
 *
 *  @param sec seconds
 */
- (void)markOvertimeAircraftByTime:(NSTimeInterval)sec andNeed2DeleteAircraft:(NSTimeInterval) deleteTime{
    // save the need discard itemss
    __block NSMutableArray *discardItems = [NSMutableArray array];
    dispatch_barrier_async(self.concurrenAircraftsArrayQueue, ^{
        [_aircraftsArrayDic enumerateKeysAndObjectsUsingBlock:^(NSString *icao, Aircraft *aircraft, BOOL *stop) {
            if (aircraft.anyLastUpdateTime != nil && [aircraft.anyLastUpdateTime timeIntervalSince1970] < sec) {
                aircraft.states = HYAircraftTimeout;
            }
            if (aircraft.anyLastUpdateTime != nil && [aircraft.anyLastUpdateTime timeIntervalSince1970] < deleteTime) {
                aircraft.states = HYAircraftWillBeDeleted;
            }
            
            // 重新激活
            if (aircraft.anyLastUpdateTime != nil && [aircraft.anyLastUpdateTime timeIntervalSince1970] > sec) {
                aircraft.states = HYAircraftActive;
            }
            
            if (aircraft.states == HYAircraftWillBeDeleted) {
                [discardItems addObject:@(aircraft.ICAOAddr)];
            }
            // 删除TXLUXX航班
            if (aircraft && aircraft.aircraftIdentity && [aircraft.aircraftIdentity length] >= 4 &&[[aircraft.aircraftIdentity substringToIndex:4] isEqualToString:@"TXLU"]) {
                [discardItems addObject:@(aircraft.ICAOAddr)];
            }
        }];
        if (discardItems.count > 0) {
            [_aircraftsArrayDic removeObjectsForKeys:discardItems];
        }
    });
#ifdef DEBUG
//    NSLog(@"飞机总数:%lu",(unsigned long)_aircraftsArrayDic.count);
#endif
}

- (void)decodeMutiADSBMessageWithData:(NSData *)data{
    int result = -9;
    NSString *strTemp = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
#ifdef DEBUG
    //NSLog(@"%@", strTemp);
#endif
    //data
    if (data.length < 20) {
        //short message. Not solve  now
        return;
    }
    for (int i=0; i<strTemp.length; i++) {
        if ( [strTemp characterAtIndex:i] == '*') {
            if (i + 30 < strTemp.length && [strTemp characterAtIndex:i+30] == '\r') {
                result = [self decodeADSBMessageWithData:[data subdataWithRange:NSMakeRange(i+1, 31)]];
                if (result != 1) {
                    //NSLog(@"result:%d",result);
                }
                i = i + 32;
            }
        }
    }
}

/**
 *  decode the adsb data
 *
 *  @param data data description
 *
 *  @return 1:success decode,0:message sames,-1:data transport error,-2:subtype error,-3:undefined formatTypeCode , -4 for short message, -5 meaningless df value
 */
- (int)decodeADSBMessageWithData:(NSData *)data{
    NSData *tempData = data;
    if (data.length < 20 || data.length > 31) {
        //short message. Not solve  now
        return -4;
    }
    // 报文数据指针 pointer to raw data buffer
    unsigned char *dataPointer = NULL;
    int DFValue = -1;
    // format type code
    unsigned int formatTypeCode;
    // uc:ADSB发射器类型（定义了飞机的种类）
    unsigned char uc;
    // dubfLast diffs from the dbuf flag
    bool changedFlag = false;
    // checksum for odd/even check
    unsigned long int checkSum;
    // remainder
    unsigned long int remainder;
    // checksum / interrogator
    unsigned long int clic;
    // icao
    unsigned long int icaoValue;
    // 6th-8th value
    int value6_8;
    //???
    unsigned long int eac;
    // on surface flag
    int groundFlag;
    // temp Plane
    __block Aircraft *aircraft;
    // temp int
    unsigned long int tempValue = 0; int secondTempValue = 0;
    
    _usedPackets++;
    
    DFValue = [self convert112AVRData:tempData];
    dataPointer = &Dbuf[0];			/* pointer for convenience */
    
    // 比较连续两次收到的报文是否相同
    for (int i=0; i<(sizeof Dbuf); i++)
    {
        if (Dbuf[i] != DbufLast[i]) changedFlag = true; /* remember difference */
        DbufLast[i] = Dbuf[i];	/* save */
    }
    if (!changedFlag) return 0;
    // save time
    self.dataTime = [NSDate date];
    
    if (DFValue == 17 || DFValue == 18 || DFValue == 19)
    {
        // 奇偶校验
        checkSum = RemPar(dataPointer,&remainder,112);
        // 相异或 如果非零，则传输的信息不正确
        clic = (checkSum^remainder);
        if(clic != 0){
            //message transport error
            dataPointer = NULL;
#ifdef DEBUG
            NSLog(@"CRC error");
#endif
            return -1;
        }
        // icao address 每架飞机唯一的标识符
        icaoValue = SepAA(dataPointer);
        // 依据ICAO地址检查该飞机是否出现过 if not seen before
        aircraft = [_aircraftsArrayDic objectForKey:@(icaoValue)];
        if (!aircraft)
        {
            aircraft = [[Aircraft alloc] initWithIcao:icaoValue];
            dispatch_barrier_async(self.concurrenAircraftsArrayQueue, ^{
                [_aircraftsArrayDic setObject:aircraft forKey:@(aircraft.ICAOAddr)];
            });
        }
        // mark working on
        aircraft.anyLastUpdateTime = 0;
        // ca/cf/af
        value6_8 = Sep0608(dataPointer);
        
        if (DFValue < 18) aircraft.capabilityCA = value6_8;	/* is ca */
        
        /* for DF17 DF18 DF19 */
        
        if (DFValue == 18) aircraft.controlCF = value6_8;
        if (DFValue == 19) aircraft.applicationAF = value6_8;
    
        // point to ME field
        dataPointer += 4;
        //读取ME（33-88 [56]）中的    uc:ADSB发射器类型（定义了飞机的种类）
        formatTypeCode = FetchFTC(dataPointer,&uc);
        // FTC 0  无位置消息   altitude only
        if (formatTypeCode == 0)
        {
            aircraft.surveillanceStatus = FetchSS(dataPointer);  /* surveill. status */
            aircraft.NICSupplement = FetchNICSB(dataPointer);  /* nic supl. b  */
            aircraft.timeSyncBit = FetchTBit(dataPointer);  /* t bit */
            
            eac = FetchEAC(dataPointer);
            int altSourceCode;
            aircraft.alt = AC2FT(eac,&altSourceCode);
            aircraft.altSourceCode = altSourceCode;
            
            aircraft.altSource = DFValue;
            aircraft.altSourceFTC = formatTypeCode;
            // mark last alt update
            aircraft.altLastUpdateTime = self.dataTime;
            aircraft.ftcOfLastPostiion = formatTypeCode;
            [self DFFinish:aircraft withDF:DFValue];
            return 1;
        }
        // FTC 1 .. 4 飞机身份与类型消息  identification
        if (formatTypeCode <= 4)
        {
            //飞机的种类 category
            aircraft.aircraftCategory = uc;
            aircraft.aircraftCategoryFTC_01_04 = formatTypeCode;
            //读取飞机ICAO地址
            char acident[9];
            // Bit(41-88)
            MB2Ident(dataPointer+1, acident);
            aircraft.aircraftIdentity = [NSString stringWithCString:acident encoding:NSASCIIStringEncoding];
            [self DFFinish:aircraft withDF:DFValue];
            return 1;
        }
        // FTC 19 读取空中速度信息  airborn velocity
        if (formatTypeCode == 19)
        {
            /* data to plane structure direct */
            /* returns 0 on success           */
            /*         1 on subtype error     */
            if ([self aircraftVel:dataPointer withAircraft:aircraft])
            {
                [self DFFinish:aircraft withDF:DFValue];
                return -2;
            }
            
            aircraft.courseAndSpeedLastTimeUpdate = self.dataTime;
            [self DFFinish:aircraft withDF:DFValue];
            return 1;
        }
        
        // FTC 5 .. 22 位置消息  position  Type5-Type8 ground; other type is air
        // Type5-8 non height info; Type9-18 大气压高度; Type20-22 GNSS高度（HAE）
        if ((formatTypeCode >= 5) && (formatTypeCode <= 22))
        {
            // assume airborne
            groundFlag = 0;
            //on surface  如果ftc小于9，就是地面位置
            if (formatTypeCode < 9) groundFlag++;
            if (!groundFlag) 			/* airborne ... */
            {
                aircraft.onGroundFlag = NO;
                // 监视状态 bit6-bit7  is the surveillance Status (Surveillance status)
                aircraft.surveillanceStatus = FetchSS(dataPointer);
                // 天线使用 bit8 indicates the antennas used  (NIC suppliment-B)
                aircraft.NICSupplement = FetchNICSB(dataPointer);
                // bit 21 contains theT(Time)bit, 0 means not synchronized to UTC
                aircraft.timeSyncBit = FetchTBit(dataPointer);
            }
            else                        /* ground      */
            {
                aircraft.onGroundFlag = YES;
                // movement on surface
                tempValue = FetchMOV(dataPointer);
                // speed over ground in kn ...
                aircraft.speedOverGroundInKN = MOV2SPD(tempValue);
                // track on surface,  course over ground
                aircraft.courseOverGround = [self GTRKHDG:dataPointer];
            }
            
            // Bit 22 contains the F flag which indicates which CPR format is used(odd or even) i.e. CPR odd/even flag
            
            CPRfromME(dataPointer, [aircraft cpr]);
            // 接收的是第一个位置帧
            if (aircraft.cpr->t_s == 0)		/* need ref. point */
            {
                tempValue = 0;
                /* find global absolut pos.
                 *  from odd and even */
                tempValue = (aircraft.cpr->cprf+1)&0x1;
                //  both exist ...
                if (aircraft.cpr->t[tempValue] != 0)
                {
                    secondTempValue = CPR2LL(aircraft.cpr,groundFlag); /* ... find pos. */
                    // valid data
                    if (secondTempValue == 0)
                    {
                        EFBPosition *lastPos = aircraft.position;
                        EFBPosition *newPos = [[EFBPosition alloc] init];
                        newPos.lon = aircraft.cpr->lon_s;
                        newPos.lat = aircraft.cpr->lat_s;
                        if (![lastPos isEqual:newPos]) {
                            [aircraft.historyPosition efb_enqueue:lastPos];
                            aircraft.position = newPos;
                        }
                        aircraft.positionLastUpdateTime = [NSDate dateWithTimeIntervalSince1970:aircraft.cpr->t_s];
                        aircraft.ftcOfLastPostiion = formatTypeCode;  /* position source ftc */
                        aircraft.positionLastUpdateTime = self.dataTime;
                        aircraft.position.isValid = YES;
                    }
                }
                else
                {   //只有一个位置帧，不能解码， 读高度信息？？
                    //df_fin(p,dfx);
                    //[self DFFinish:aircraft withDF:DFValue];
                    //return 1;
                }
            }
            else				//基于上一个位置参考点来进行计算
            {
                if ((secondTempValue = RCPR2LL(aircraft.cpr,groundFlag)) < 0)
                {
                    //snprintf(Str,sizeof Str,"RCPR2LL error %d",secondTempValue);
                    //log_to_file(Str);;
                }
                if (aircraft.cpr->t_s > 1)
                {
                    EFBPosition *lastPos = aircraft.position;
                    EFBPosition *newPos = [[EFBPosition alloc] init];
                    newPos.lon = aircraft.cpr->lon_s;
                    newPos.lat = aircraft.cpr->lat_s;
                    if (![lastPos isEqual:newPos]) {
                        if (lastPos.isValid)
                            [aircraft.historyPosition efb_enqueue:lastPos];
                        aircraft.position = newPos;
                    }
                    aircraft.positionLastUpdateTime = [NSDate dateWithTimeIntervalSince1970:aircraft.cpr->t_s];
                    aircraft.ftcOfLastPostiion = formatTypeCode;  /* position source ftc */
                    aircraft.groundSpeedAndAngleIsValid = YES;
                    aircraft.positionLastUpdateTime = self.dataTime;
                    aircraft.position.isValid = YES;
                }
            }
            if (!groundFlag)
            {				/* real altitude */
                eac = FetchEAC(dataPointer);
                int status;
                aircraft.alt = AC2FT(eac,&status);
                aircraft.altSourceCode = status;
            }
            aircraft.altSource = DFValue;
            aircraft.altSourceFTC = formatTypeCode;
            // mark last alt update
            aircraft.altLastUpdateTime = self.dataTime;
            [self DFFinish:aircraft withDF:DFValue];
            return 1;
        }
        
        // FTC 28 only subtype=1 decoded  扩展间歇振荡器飞机状况消息(紧急，优先状况)
        if (formatTypeCode == 28)
        {
            if (uc == 1)
            {
                aircraft.emergencyState = (int)FetchEMS(dataPointer+1);
                aircraft.urgencyAndPriority = N2SQ(Sep2032(dataPointer-1));  /* Mode A, bits 12..24*/
            }
            [self DFFinish:aircraft withDF:DFValue];
            return 1;
        }
        [self DFFinish:aircraft withDF:DFValue];
        return -3;
    }
    [self DFFinish:aircraft withDF:DFValue];
    return -5;
}


/**
 task after finish decoding DF 删除超时的飞机

 @param aircraft <#aircraft description#>
 @param dfValue <#dfValue description#>
 */
- (void)DFFinish:(Aircraft *)aircraft withDF:(int)dfValue
{
    if (!aircraft) {
        return;
    }
    if (aircraft.ICAOAddr <= 0) {
#ifdef DEBUG
        NSLog(@"error: undefine DF value");
#endif
        return;
    }
    if (aircraft.states == HYAircraftTimeout)
        aircraft.states = HYAircraftActive;
    
    // insert in data structure ...
    // time of last update 上次更新的时间
    // sec from 1970-01-01
    aircraft.anyLastUpdateTime = self.dataTime;
    // mask of received DF 如果DF=17,p->dstat = 131072
    aircraft.dataStatus |= 0x1<<dfValue;
    // 上一次收到的DF值
    aircraft.lastUpdateDF = dfValue;
    // 总共更新的次数
    aircraft.totalUpdateTimes = aircraft.totalUpdateTimes + 1;
    // any update
    self.timeOfAnyUpadate = self.dataTime;
    self.usedPackets = self.usedPackets + 1;
    // 一直没有收到方向信息
    if (!aircraft.groundSpeedAndAngleIsValid) {
        // solve code
    }
}

#pragma mark - getter & setter
/** 写操作aircraftsArray时用实例变量，读操作用点语法*/
- (NSMutableDictionary *)aircraftsArrayDic{
    __block NSMutableDictionary *dic;
    dispatch_sync(self.concurrenAircraftsArrayQueue, ^{
        dic = [NSMutableDictionary dictionaryWithDictionary:_aircraftsArrayDic];
    });
    return dic;
}

/** 清除数据*/
- (void)clearAllData{
    dispatch_barrier_async(self.concurrenAircraftsArrayQueue, ^{
        [_aircraftsArrayDic removeAllObjects];
    });
}

/** 获取数据*/
- (NSDictionary *)fetchData {
    return [NSDictionary dictionaryWithDictionary:self.aircraftsArrayDic];
}

@end
