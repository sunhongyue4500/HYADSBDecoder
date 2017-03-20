;//
//  Aircraft.m
//  EFB
//
//  Created by Sunhy on 16/1/20.
//  Copyright © 2016年 Buaa. All rights reserved.
//

//#import <MaplyComponent.h>
//#import <WhirlyGlobeComponent.h>
#import "Aircraft.h"
#import "EFBPosition.h"

@interface Aircraft ()

@end

@implementation Aircraft

- (instancetype)initWithIcao:(unsigned long int)icao {
    if (self = [super init]) {
        _ICAOAddr = icao;
        _anyLastUpdateTime = nil;
        _totalUpdateTimes = 0;
        _urgencyAndPriority = 0;
        _aircraftCategory = 0;
        _aircraftCategoryFTC_01_04 = -1;
        _aircraftIdentity = @"";
        _position = [[EFBPosition alloc] init];
        _ftcOfLastPostiion = -1;
        _positionLastUpdateTime = nil;
        _alt = -99999.;
        _altSource = -1;
        _altSourceFTC = -1;
        _altSourceCode = -1;
        _altDiffGNSSHeight = -99999.;
        _altLastUpdateTime = nil;
        _speedOverGroundInEast = -99999.;
        _speedOverGroundInNorth = -99999.;
        _heading = -99999.;
        _airSpeedIndicated = -99999.;
        _tas = -99999.;
        _speedOverGroundInKN = -99999.;
        _courseOverGround = -99999.;
        _verticalSpeed = -99999.;
        _verticalSpeedSource = -1;
        _courseAndSpeedLastTimeUpdate = nil;
        _clic = -1;
        _capabilityCA = -1;
        _controlCF = -1;
        _applicationAF = -1;
        _flightStatus = -1;
        _downlinkRequest = -1;
        _utilityMessage = -1;
        _verticalStatus = -1;
        _crossLinkCap = -1;
        _replyInfo = -1;
        _surveillanceStatus = -1;
        _NICSupplement = -1;
        _timeSyncBit = -1;
        // assum airbone
        _onGroundFlag = NO;
        _emergencyState = -1;
        
        _lastUpdateDF = -1;
        _dataStatus = 0;
        
        _cpr = (struct CPR *)malloc(sizeof(struct CPR));
        _cpr->cprf = -1;
        _cpr->t[0]  = 0;
        _cpr->yz[0] = 0;
        _cpr->xz[0] = 0;
        _cpr->rlat[0] = 0.;
        _cpr->rlon[0] = 0.;
        _cpr->t[1] = 0;
        _cpr->yz[1] = 0;
        _cpr->xz[1] = 0;
        _cpr->rlat[1] = 0.;
        _cpr->rlon[1] = 0.;
        _cpr->t_s = 0;			/* ! 0 here (used as flag too) */
        _cpr->lat_s = -99999.;
        _cpr->lon_s = -99999.;
        
        _states = HYAircraftActive;
        
        //**************** ADCC
        _historyPosition = [NSMutableArray array];
        _historyAlt = [NSMutableArray array];
        _speedOverGroundInKNTest = -1.0;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@:%p %@", [self class], self,
            @{@"ICAO" : [NSNumber numberWithUnsignedLong:_ICAOAddr],
              @"updateTime" : _anyLastUpdateTime,
              @"lon" : [NSNumber numberWithDouble:_position.lon],
              @"lat" : [NSNumber numberWithDouble:_position.lat]}];
}

//- (void)dealloc {
//    //free(_cpr);
//}
//
//#pragma mark - NSCopying Delegate Method
//- (id)copyWithZone:(nullable NSZone *)zone{
//    Aircraft *aircraft = [[Aircraft allocWithZone:zone] init];
//    aircraft.ICAOAddr = self.ICAOAddr;
//    aircraft.states = self.states;
//    aircraft.anyLastUpdateTime = [self.anyLastUpdateTime copy];
//    aircraft.aircraftIdentity = self.aircraftIdentity;
//    aircraft.courseOverGround = self.courseOverGround;
//    aircraft.alt = self.alt;
//    aircraft.verticalSpeed = self.verticalSpeed;
//    aircraft.speedOverGroundInKN = self.speedOverGroundInKN;
//    aircraft.lon = self.lon;
//    aircraft.lat = self.lat;
//    aircraft.positionLastUpdateTime = [self.positionLastUpdateTime copy];
//    aircraft.courseAndSpeedLastTimeUpdate = [self.courseAndSpeedLastTimeUpdate copy];
//    aircraft.altLastUpdateTime = [self.altLastUpdateTime copy];
//    return aircraft;
//}

@end
