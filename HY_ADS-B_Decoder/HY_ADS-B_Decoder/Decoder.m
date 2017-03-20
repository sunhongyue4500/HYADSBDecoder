//
//  Decoder.m
//  EFB
//
//  Created by Sunhy on 16/3/2.
//  Copyright © 2016年 Buaa. All rights reserved.
//

#import "Decoder.h"
//#import "EFBSaveTool.h"
//#import "EFBConstants.h"

// 保存每一条报文数据，共14个字节（112bit）,最后一个字节是同步用,raw data buffer (14 data, 1 sync)
//unsigned char Dbuf[15];
////last dbuf
//unsigned char DbufLast[15];
//unsigned char Sbuf[32];
NSMutableArray *pointerArray;

static struct Plane *emptyPlane = NULL;
//data time. receive time of date in realtime or time from save file on replay
time_t dataTime;
//last(old) data time
static time_t d_tim_o;
// marks update of any structure


#define allocPlaneNum 50
#define ALLOC_PLANE_SPACE 50

#pragma mark - newAdd

/* ------------------------------------------------------------------------
 * initialize empty plane structure
 * unknown values are (mostly) set to:
 *	0			if 0 not a valid data
 *	-1			if 0 is a valid data and -1 is not
 *				  and data is a signed value
 * 	<out of range value>	otherwise
 * ------------------------------------------------------------------------ */
void pl_empty_init (struct Plane *p)
{
    p->icao = 0;				/* icao address */
    p->utms = 0;				/* time of last update in UNIX sec */
    p->total = 0;			/* total update count */
    p->urgencyAndPriority = 0;				/* identity (squawk 故障) DF05 DF21 */
    p->acc = 0;				/* aircraft category DF17 FTC01..04 */
    p->acc_ftc = -1;			/* aircraft category FTC01..04 */
    p->acident[0] = '\000';		/* aircraft ident DF17 FTC01..04 */
    p->lat = -9999.;			/* actual position data */
    p->lon = -9999.;
    p->pos_ftc = -1;			/* ftc of position */
    p->ll_t = 0;
    p->alt = -9999;			/* altitude [ft] DF04 DF00 */
    p->alt_s = -1;			/* altitude source (DFnn) */
    p->alt_ftc = -1;			/* altitude source subtype (FTC) */
    p->alt_c = -1;			/* altitude source coding */
    p->alt_d = -9999.;			/* altitude / height difference */
    p->alt_t = 0;			/* time of last alt update */
    p->veast = -9999.;			/* speed in east dir. */
    p->vnorth = -9999.;			/* speed in north dir. */
    p->sogc = -9999.;			/* speed over ground computed */
    p->cogc = -9999.;			/* course over ground computed */
    p->hdg = -9999.;			/* heading */
    p->ias = -9999.;			/* indicated airspeed */
    p->tas = -9999.;			/* true airspeed */
    p->vert = -9999;			/* vertical speed */
    p->verts = -1;			/* source of vertical speed */
    p->cs_t = 0;				/* time of last course and speed */
    p->clic = -1;			/* interrogator */
    p->ca = -1;				/* capability DF11 DF17 */
    p->cf = -1;				/* control DF18 */
    p->af = -1;				/* application DF19 */
    p->fs = -1;				/* flight status DF04*/
    p->dr = -1;				/* downlink request DF04 */
    p->um = -1;				/* utility message DF04 */
    p->vs = -1;				/* vertical status DF00 */
    p->cc = -1;				/* cross-link cap. */
    p->ri = -1;				/* reply info */
    p->sstat = -1;			/* surveillance status */
    p->nicsb = -1;			/* NIC supplement B */
    p->tbit = -1;			/* time sync bit */
    p->g_flag = -1;			/* set if on ground */
    p->ems = -1;				/* emergency state */
    /* struct CPR position data
     *   used for decoding */
    p->pos.cprf = -1;
    p->pos.t[0] = 0;
    p->pos.yz[0] = 0;
    p->pos.xz[0] = 0;
    p->pos.rlat[0] = 0.;
    p->pos.rlon[0] = 0.;
    p->pos.t[1] = 0;
    p->pos.yz[1] = 0;
    p->pos.xz[1] = 0;
    p->pos.rlat[1] = 0.;
    p->pos.rlon[1] = 0.;
    p->pos.t_s = 0;			/* ! 0 here (used as flag too) 标记没有参考点，没有接收到一个位置帧*/
    p->pos.lat_s = -9999.;
    p->pos.lon_s = -9999.;
    
#ifdef BDS_DIRECT
    p->bds.fcu_alt_40 = -9999.;		/* mcp/fcu selected altitude [ft] */
    p->bds.fms_alt_40 = -9999.;		/* fms selected altitude [ft] */
    p->bds.baro_40 = 0;			/* baro setting [millibar] */
    p->bds.vnav_40 = -1;			/* vnav mode [0/1]*/
    p->bds.alt_h_40 = -1;		/* altitude hold [0/1]*/
    p->bds.app_40 = -1;			/* approach mode [0/1]*/
    p->bds.alt_s_40 = -1;		/* target altitude source [0..3] */
    
    /* from bds 5.0: */
    p->bds.roll_50 = -9999.;		/* roll angle [degr] */
    p->bds.track_50 = -9999.;		/* true track [0..360 degr] */
    p->bds.g_speed_50 = -9999.;		/* ground speed [kn] */
    p->bds.t_rate_50 = -9999.;		/* track angle rate [degr./sec] */
    p->bds.tas_50 = -9999.;		/* true airspeed [kn] */
    
    /* from bds 6.0: */
    p->bds.hdg_60 = -9999.;		/* magnetic heading [0..360 degr.] */
    p->bds.ias_60 = -9999.;		/* indicated airspeed [kn] */
    p->bds.mach_60 = -9999.;		/* mach ??? */
    p->bds.vert_b_60 = -9999.;		/* vertical speed, baro based
                                     *   [ft/min] */
    p->bds.vert_i_60 = -9999.;		/* vertical speed, ins based
                                     *   [ft/min] */
    
    p->bds.l_bds = -1.;			/* last bds decoded */
    p->bds.t_bds = 0.;			/* time of last bds decoding */
#endif
    
    p->lastdf = -1;			/* DF of last update */
    p->dstat = 0;			/* data status (bitmask) */
    
    return;
}

/**
 *  init the global empty plane for later using. Call once
 */
void plane2EmptyInit(){
    if(emptyPlane == NULL)
        emptyPlane = (struct Plane *)malloc(sizeof(struct Plane));
    pl_empty_init(emptyPlane);
}

/**
 *  task after finish decoding DF 未删除超时的飞机
 *
 *  @param p       <#p description#>
 *  @param dfValue <#dfValue description#>
 */
void DFfinish(struct Plane *p, int dfValue)
{
    if (!p) {
        return;
    }
    
    if (p -> icao <= 0) {
#ifdef DEBUG
        NSLog(@"error: undefine DF value");
#endif
        return;
    }
    
    time_t sec;
    // insert in data structure ...
    // time of last update 上次更新的时间
    // sec from 1970-01-01
    p->utms = dataTime;
    // mask of received DF 如果DF=17,p->dstat = 131072
    p->dstat |= 0x1<<dfValue;
    // 上一次收到的DF值
    p->lastdf = dfValue;
    // 总共更新的次数
    p->total++;
    
    t_flag = dataTime;
    //count used packets
    usedPackets++;
    
    // check the overtime plane
    
    
    if (dataTime != d_tim_o)
    {
        d_tim_o = dataTime;		/* remember last pass */
        // delete outdated planes from shared memory
        // delete if never update in kPlaneLifetime
        //sec = dataTime - kPlaneLifetime;
        //sec = dataTime - [EFBSaveTool IntForKey:kAircraftLifeTimeUserDefualtKey];
        deleteOvertimePlanByTime(sec);
    }

}

/**
 *  get misc pointer by shm_ptr
 *
 *  @param shm_ptr <#shm_ptr description#>
 *
 *  @return <#return value description#>
 */
struct Misc *pointer2miscWithShm_ptr(void *shm_ptr)
{
    return (struct Misc *)((long int)shm_ptr + (allocPlaneNum+1)*sizeof(struct Plane));
}

/**
 *  find the plane of particular shm_ptr and particular position
 *
 *  @param shm_ptr shm_ptr pointer
 *  @param i       index (0 - allocPlaneNum-1)
 *
 *  @return if not found,return NULL
 */
struct Plane *pptrWithShm_ptrAndIndex(void *shm_ptr,int i)
{
    long int n;
    if ((i<0) || (i>allocPlaneNum)) return(NULL);
    n = i * sizeof(struct Plane);
    n += (long int)shm_ptr;
    return (struct Plane *)n;
}

//let num = 50 first
/**
 *  add a memary(shm_ptr+misc) with plane num, now is 50
 *
 *  @param num plane num
 */
bool addMemaryWithPlaneNum(int num){
    //first position is an empty plane
    void *shm_ptr = malloc(sizeof(struct Plane) * num + sizeof(struct Misc));
    if (shm_ptr == NULL)
        return false;
    // initialize the first Plane structure with  unknown/empty data
    struct Plane *p_2_empty = (struct Plane *)((long int)shm_ptr);
    pl_empty_init(p_2_empty);
    if (emptyPlane == NULL) {
        //call only one time
        plane2EmptyInit();
    }
    // copy pl_empty to all structures in shared memory
    for (int i=1; i<num; i++) *pptrWithShm_ptrAndIndex(shm_ptr, i) = *emptyPlane;     //对其他飞机初始化
    // pointer to Misc structure (just behind the last Plane structure)
    struct Misc *p_mi = pointer2miscWithShm_ptr(shm_ptr);
    //init for misc
    p_mi->maxPlaneNum = num;
    p_mi->validPlaneCount = 0;
    p_mi->isFull = false;
    p_mi->P_MAX_C = 0;
    // time of last update and flag 更新标志
    p_mi->t_flag = 0;
    
    if(!pointerArray)
        pointerArray = [[NSMutableArray alloc] init];
    [pointerArray addObject:[NSValue valueWithPointer:shm_ptr]];
    return true;
}

/**
 *  check memary will full
 *
 *  @return true when full
 */
bool allMemaryspaceIsFull(){
    int validPlaneSum = 0;
    NSValue *pointerValue;
    struct Misc *p_mi;
    //如果空位置小于20则认为will full
    for (pointerValue in pointerArray) {
        void *shm_ptr = pointerValue.pointerValue;
        p_mi = pointer2miscWithShm_ptr(shm_ptr);
        validPlaneSum += p_mi->validPlaneCount;
        if(p_mi->isFull)
            break;
    }
    if(pointerArray.count - validPlaneSum > 20)
        return false;
    return true;
}

/**
 *  add memary space by plan's count
 *
 *  @param planeCount plane's count
 *
 *  @return true when increase successfully
 */
bool increaseMemaryByPlaneCount(int planeCount){
    if (allMemaryspaceIsFull())
        if (addMemaryWithPlaneNum(planeCount))
            return true;
    return false;
}

/**
 *  return DF value and assign the Dbuf
 *
 *  @param data adsb data
 *
 *  @return DF value
 */
//int convertData(NSData *data)
//{
//    int n;
//    NSString *dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//    char * myBuffer = (char *)malloc((int)[dataStr length] / 2 + 1);
//    if (myBuffer == NULL) return -1;
//    for (int i = 0; i < [dataStr length] - 1; i += 2) {
//        unsigned int anInt;
//        NSString * hexCharStr = [dataStr substringWithRange:NSMakeRange(i, 2)];
//        NSScanner * scanner = [[NSScanner alloc] initWithString:hexCharStr];
//        [scanner scanHexInt:&anInt];
//        myBuffer[i / 2] = (char)anInt;
//    }
//    
//    for(int k=0;k<dataStr.length;k++){
//        Sbuf[k] = myBuffer[k];
//    }
//    free(myBuffer);
//    myBuffer = NULL;
//    for(n=0;n<14;n++){
//        Dbuf[n] = Sbuf[n];
//    }
//    // 返回DF
//    // 1----5
//    // MSB-LSB
//    return ((Dbuf[0])>>3)&0x1f;	/* df, isolated */
//}

bool updatePlanInfoByICAO(unsigned long icao){
    //search first
    struct Plane *aPlane = findAPlaneByICAO(icao);
    if(aPlane != NULL){
        
    }
        
    return true;
}

/**
 *  clear the over time Plane  sec = dataTime - LIFE_TIME
 *  (it has never update its info in sec)
 *
 */
void deleteOvertimePlanByTime(time_t sec){
    struct Plane *plane = NULL;
    NSValue *pointerValue;
    void *shm_ptr;
    struct Misc *misc;
    for (pointerValue in pointerArray) {
        shm_ptr = pointerValue.pointerValue;
        if (!shm_ptr)   continue;
        misc = pointer2miscWithShm_ptr(shm_ptr);
        if (!misc)  continue;
        for(int i=0; i<misc->P_MAX_C; i++){
            plane = pptrWithShm_ptrAndIndex(shm_ptr, i);
            if (!plane) continue;
            // delete outdated planes from shared memory
            if ((plane->utms < sec) && (plane->utms != 0))
            {
                *plane = *emptyPlane;
                totalValidPlaneNum--;
                if (totalValidPlaneNum < 0) totalValidPlaneNum = 0;
                if (i == misc->P_MAX_C) misc->P_MAX_C--;
            }
            
        }
    }
    
}

// add a Plane
bool addAPlane(struct Plane *plane){
    struct Plane *aplane = findAEmptyPlaneSpace();
    if (aplane != NULL && plane != NULL) {
        *aplane = *plane;
        return true;
    }
    return false;
}

/**
 *  find a particular plane from particular shm_ptr
 *
 *  @param shm_ptr particular shm_ptr
 *  @param p_mi    particular p_mi
 *  @param icao    icao address
 *
 *  @return NULL if not found
 */
struct Plane* findAPlaneByICAOFromASharedMemary(void *shm_ptr, struct Misc *p_mi, unsigned long icao){
    struct Plane *p = NULL;
    if (icao > 1)
    {
        for (int i=0; i <= p_mi->P_MAX_C; i++)
        {
            p = pptrWithShm_ptrAndIndex(shm_ptr, i);
            if (p->icao == icao) return (p);
        }
    }
    return NULL;
}

/**
 *  find a plan from all space by icao
 *
 *  @param icao icao addr
 *
 *  @return NULL if not found
 */
struct Plane* findAPlaneByICAO(unsigned long icao){
    struct Plane *plane = NULL;
    NSValue *pointerValue;
    void *shm_ptr;
    struct Misc *p_mi;
    if (!pointerArray) {
        pointerArray = [[NSMutableArray alloc] init];
    }
    for (pointerValue in pointerArray) {
        shm_ptr = pointerValue.pointerValue;
        p_mi = pointer2miscWithShm_ptr(shm_ptr);
        if(findAPlaneByICAOFromASharedMemary(shm_ptr, p_mi, icao) != NULL)
            return plane;
    }
    return NULL;
}



bool freeMemary(){
    return true;
}

/**
 *  find the Misc pointer from particular shm_ptr
 *
 *  @return Misc pointer
 */
struct Misc *pointer2miscFromShm_ptr(void *shm_ptr)
{
    return (struct Misc *)((long int)shm_ptr + (ALLOC_PLANE_SPACE)*sizeof(struct Plane));
}

/**
 *  find an empty space from all memary space
 *
 *  @return if not found,return NULL
 */
struct Plane* findAEmptyPlaneSpace(void *shm_ptr){
    if (pointerArray.count == 0) {
        addMemaryWithPlaneNum(ALLOC_PLANE_SPACE);
    }
    struct Plane *plane = NULL;
    NSValue *pointerValue;
    void *tempShm_ptr;
    struct Misc *p_mi;
    for (pointerValue in pointerArray) {
        tempShm_ptr = pointerValue.pointerValue;
        p_mi = pointer2miscWithShm_ptr(tempShm_ptr);
        for(int i=0; i<p_mi->maxPlaneNum; i++){
            plane = pptrWithShm_ptrAndIndex(tempShm_ptr, i);
            if (plane !=  NULL && plane->icao == 0) {
                if (i > p_mi->P_MAX_C) p_mi->P_MAX_C = i;
                // return the shm_ptr that the plane belongs to
                shm_ptr = tempShm_ptr;
                return plane;
            }
        }
    }
    return NULL;
}
