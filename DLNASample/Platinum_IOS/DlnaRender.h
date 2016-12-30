//
//  DlnaRender.h
//  demo
//
//  Created by liaogang on 15/6/30.
//  Copyright (c) 2015年 com.cs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Platinum/Platinum.h>
#import "MediaRendererDelegate.h"
#import "PlatinumIOSConst.h"

@class MediaPanel,MediaPanelN2H,MediaPanelH2N;

@protocol DLNAActionListener;

/**
 should call [[NSUserDefaults standardUserDefaults] synchronize] when applicationDidEnterBackground
 */
@interface DlnaRender : NSObject

+(instancetype)shared;

-(PLT_DeviceDataReference)getDevice;


@property (nonatomic,strong) MediaPanelN2H *controller;
@property (nonatomic,strong) MediaPanelH2N *mydirty;

// weak reference
-(void)addActionListener:(id<DLNAActionListener>) listener;
-(void)removeActionListener:(id<DLNAActionListener>)listener;

// notify the network controller client, render status is changed.
-(void)notifyDirty;

@end



@protocol DLNAActionListener <NSObject>
@required
-(void)actionComing:(DLNAActionType)type from:(MediaPanelN2H*)controller;
@end


class PLT_MediaRendererMy :public PLT_MediaRenderer
{
public:
    PLT_MediaRendererMy(const char*  friendly_name,
                      bool         show_ip = false,
                      const char*  uuid = NULL,
                      unsigned int port = 0,
                        bool         port_rebind = false);
    NPT_Result SetupServices();
    void MediaChanged(MediaPanel *media);
private:
    PLT_Service *_serviceAVTransport, *_serviceRenderingControl, *_serviceConnectionManager;
};



extern NSString *kNotifyDMRStopped;

extern NSString *kNotifyDMRStarted;
