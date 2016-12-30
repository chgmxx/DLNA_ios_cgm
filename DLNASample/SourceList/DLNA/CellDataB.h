//
//  CellDataA.h
//  Genie_Main
//
//  Created by liaogang on 16/7/21.
//  Copyright © 2016年 netgear. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CellDataA.h"
#import <Platinum/Platinum.h>

@interface CellDataA (plt)

-(instancetype)initWithMediaObjectRf:(PLT_MediaObjectReference)media;

-(instancetype)initWithMediaObject:(PLT_MediaObject*)media;

@end

@interface MediaDevice (plt)
-(instancetype)initWithPLT_DeviceDataReference:(PLT_DeviceDataReference)device;
@end

NSString* uintSizeDescription(NPT_LargeSize size);
NSString *secondDescription(NPT_UInt32 seconds);
