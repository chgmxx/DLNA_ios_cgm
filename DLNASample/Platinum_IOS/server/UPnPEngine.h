//
//  UPnPEngine.h
//  demo
//
//  Created by geine on 6/16/15.
//  Copyright (c) 2015 com.cs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Platinum/Platinum.h>


/**
 should call [[NSUserDefaults standardUserDefaults] synchronize] when applicationDidEnterBackground
 */
@interface UPnPEngine : NSObject

-(instancetype)init NS_UNAVAILABLE;

+ (instancetype)getEngine;


@end

extern NSString *kNotifyDMSStopped;

extern NSString *kNotifyDMSStarted;
