//
//  Aircraft.h
//  EFB
//
//  Created by Sunhy on 16/1/20.
//  Copyright © 2016年 Buaa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "mds02.h"
@class MaplyViewTracker;
@class EFBPosition;
#define INVALID_AIRCRAFT_DOUBLE_VALUE -9999.

typedef NS_ENUM(NSUInteger, HYAircraftStates){
    HYAircraftNonActive,
    /** 活动状态*/
    HYAircraftActive,
    /** 超时状态*/
    HYAircraftTimeout,
    HYAircraftWillBeDeleted,
    HYAircraftDidDeleted
};

@interface Aircraft : NSObject

#pragma mark - **************** ADSB
@property (nonatomic) struct CPR *cpr;
/** icao 地址*/
@property (nonatomic, assign) unsigned long int ICAOAddr;
/** time of any last update   NULL if dataset is in update */
@property (nonatomic, strong) NSDate *anyLastUpdateTime;
/** total updates*/
@property (nonatomic) unsigned long int totalUpdateTimes;
/** identity (squawk) (DF05 DF21)*/
@property (nonatomic) unsigned long int urgencyAndPriority;
/** aircraft category (DF17) */
@property (nonatomic) int aircraftCategory;
/** FTC of CAT (01 ..04)*/
@property (nonatomic) int aircraftCategoryFTC_01_04;
/** aircraft ident (DF17 FTC01..04*/
@property (nonatomic,copy) NSString *aircraftIdentity;
/** 当前位置*/
@property (nonatomic, strong) EFBPosition *position;
/** FTC from DF17 of last position*/
@property (nonatomic) int ftcOfLastPostiion;
/** time of update position*/
@property (nonatomic, strong) NSDate *positionLastUpdateTime;
/** altitude [ft] DF04 DF00*/
@property (nonatomic) double alt;
/** altitude source (DFnn)*/
@property (nonatomic) int altSource;
/** altitude source FTC. FTC if DF17 or DF18, 0 otherwise*/
@property (nonatomic) int altSourceFTC;
/** altitude source coding. 0=GILLHAM, 1=binary, -1=not avail, -2=metric (scaling unknown !!!)*/
@property (nonatomic) int altSourceCode;
/** difference GNSSheight - Baro (DF17 FTC19) */
@property (nonatomic) double altDiffGNSSHeight;
/** time of last alt update*/
@property (nonatomic, strong) NSDate *altLastUpdateTime;
/** speed over ground in east dir*/
@property (nonatomic) double speedOverGroundInEast;
/** speed over ground in north dir. (DF17 FTC19/1/2) */
@property (nonatomic) double speedOverGroundInNorth;
/** 航向 magnetic heading*/
@property (nonatomic) double heading;
/** airspeed indicated ... */
@property (nonatomic) double airSpeedIndicated;
/** true in kn (DF17 FTC19/3/4 */
@property (nonatomic) double tas;
/** speed over ground in kn ...对地速度*/
@property (nonatomic) double speedOverGroundInKN;
/** course over ground (degree)对地航向.if 'g_flag' = 0  computed from DF17 FTC19/1/2 ;if 'g_flag' = 1 from DF17 Surface position*/
@property (nonatomic) double courseOverGround;
/** vertical speed (ft/min)*/
@property (nonatomic) double verticalSpeed;
/** source of vertical speed. 0=GNSS, 1=Baro, -1=unknown*/
@property (nonatomic) int verticalSpeedSource;
/** time of last course and speed update (DF17 FTC19)*/
@property (nonatomic, strong) NSDate *courseAndSpeedLastTimeUpdate;
/** interrogator (DF11 DF17 DF18) */
@property (nonatomic) int clic;
/** capability CA (DF11 DF17)*/
@property (nonatomic) int capabilityCA;
/** control CF (DF18)*/
@property (nonatomic) int controlCF;
/** application AF (DF19)*/
@property (nonatomic) int applicationAF;
/** flight status (DF04) */
@property (nonatomic) int flightStatus;
/** downlink request (DF04)*/
@property (nonatomic) int downlinkRequest;
/** downlink request (DF04) */
@property (nonatomic) int utilityMessage;
/** vertical status (DF00)*/
@property (nonatomic) int verticalStatus;
/** cross-link cap. (DF00)*/
@property (nonatomic) int crossLinkCap;
/** reply info (DF00) */
@property (nonatomic) int replyInfo;
/** surveillance status (DF17)  监视状况*/
@property (nonatomic) int surveillanceStatus;
/** NIC supplement B (DF17)  单天线*/
@property (nonatomic) int NICSupplement;
/** time sync bit (DF17)*/
@property (nonatomic) int timeSyncBit;
/** set if on ground*/
@property (nonatomic) BOOL onGroundFlag;
/** emergency state (FTC 28)*/
@property (nonatomic) int emergencyState;
///** osition data (for decoding)*/
//@property(nonatomic,strong)NSValue *CPRPos;
/** DF of last update*/
@property (nonatomic) int lastUpdateDF;
/** data status (DF bitmask) .  each bit set represents a rec. DF ;  bit 0 (LSB) == DF00*/
@property (nonatomic) unsigned long int dataStatus;
/** aircraft states*/
@property (nonatomic) HYAircraftStates states;

#pragma mark - **************** ADCC
@property (nonatomic, assign) BOOL callSignIsValid;
@property (nonatomic, assign) BOOL altIsValid;
@property (nonatomic, assign) BOOL groundSpeedAndAngleIsValid;
@property (nonatomic, assign) BOOL groundAngleComputeIsValid;

/** speed test*/
@property (nonatomic) double speedOverGroundInKNTest;
/** speed over ground in km ...估算速度*/
@property (nonatomic) double computeSpeedOverGroundInKM;
/** 历史点*/
@property (nonatomic, strong) NSMutableArray *historyPosition;
/** 历史高度*/
@property (nonatomic, strong) NSMutableArray *historyAlt;

#pragma mark - **************** DEP & ARR Airport
/** marker对应航班起飞机场*/
@property (nonatomic, copy) NSString *depAirportFourWordsCode;
/** marker对应航班降落机场*/
@property (nonatomic, copy) NSString *arrAirportFourWordsCode;
/** 飞机类型A321*/
@property (nonatomic, copy) NSString *aircraftType;
@property (nonatomic, assign) BOOL depArrAirportAndaicraftTypeIsValid;

#pragma mark - **************** method
- (instancetype)initWithIcao:(unsigned long int)icao;

@end
