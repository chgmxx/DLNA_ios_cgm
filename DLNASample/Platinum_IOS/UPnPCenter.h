//
//  UPnPCenter.h
//  DLNASample
//
//  Created by liaogang on 16/11/18.
//  Copyright © 2016年 liaogang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Reachability.h"
#import <Platinum/Platinum.h>

@interface UPnPCenter : NSObject

-(instancetype)init NS_UNAVAILABLE;

+(instancetype)shared;

@property (nonatomic,readonly,assign) PLT_UPnP *pUpnp;

@property (nonatomic,strong,readonly) Reachability* reachability;

-(void)stopUpnp;

-(void)startUpnp;

-(void)addDeviceRenderer;

-(void)addDeviceServer;

-(void)addCtrlPoint;


-(void)removeDeviceRenderer;

-(void)removeDeviceServer;

-(void)removeCtrlPoint;





-(void)disableRenderer;
-(void)enableRenderer;
-(bool)isRendererEnabled;


-(void)disableServer;
-(void)enableServer;
-(bool)isServerEnabled;

@end

