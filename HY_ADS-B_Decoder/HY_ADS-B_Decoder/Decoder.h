//
//  Decoder.h
//  EFB
//
//  Created by Sunhy on 16/3/2.
//  Copyright © 2016年 Buaa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "mds02.h"
#import "decsub02.h"

// total received data packets
static unsigned long int total_p;
static unsigned long int usedPackets;    /* used data packets */
static time_t t_start;      /* time at program start */
static time_t t_flag;
// valid plane numbers in all memary space
static int totalValidPlaneNum;

//initialize empty plane structure
void pl_empty_init (struct Plane *p);

//init the global empty plane for later using. Call once
void plane2EmptyInit();

//
void DFfinish(struct Plane *p, int dfValue);

//get misc pointer by shm_ptr
struct Misc *pointer2miscWithShm_ptr(void *shm_ptr);

//get the plane of particular shm_ptr and particular position
struct Plane *pptrWithShm_ptrAndIndex(void *shm_ptr,int i);

//add a memary(shm_ptr+misc) with plane num, now is 50
bool addMemaryWithPlaneNum(int num);

//check memary will full
bool allMemaryspaceIsFull();

bool increaseMemaryByPlaneCount(int planeCount);

//return DF value and assign the Dbuf
int convertData(NSData *data);

bool updatePlanInfoByICAO(unsigned long icao);

//clear the over time Plane
void deleteOvertimePlanByTime(time_t sec);

bool addAPlane(struct Plane *plane);

//find a particular plane from particular shm_ptr
struct Plane* findAPlaneByICAOFromASharedMemary(void *shm_ptr, struct Misc *p_mi, unsigned long icao);

//find a plan from all space by icao
struct Plane* findAPlaneByICAO(unsigned long icao);

bool freeMemary();

//find the Misc pointer from particular shm_ptr
struct Misc *pointer2miscFromShm_ptr(void *shm_ptr);

//find an empty space from all memary space
struct Plane* findAEmptyPlaneSpace();

//decode the adsb data
int decodeADSBMessageWithData(NSData *data);