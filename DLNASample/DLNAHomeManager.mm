//
//  DLNAHomeViewController.m
//  iDLNA
//
//  Created by liaogang on 16/11/16.
//  Copyright © 2016年 liaogang. All rights reserved.
//

#import "DLNAHomeManager.h"
#import <Platinum/Platinum.h>
#import "UPnPEngine.h"
#import "Util.h"
#import "Macro.h"
#import "DlnaControlPoint.h"
#import "DlnaRender.h"
#import "PlayerMessage.h"
#import <AVFoundation/AVFoundation.h>
#import "constDefines.h"
#import "UPnPCenter.h"
#import "UPnPEngine.h"
#import "MediaPanel.h"


@interface DLNAHomeManager ()
<DLNAActionListener,
ControlPointEventListener>
{
    UIBackgroundTaskIdentifier bgTask;
    bool rendererPresenting;
}

@property (nonatomic,strong) NSMutableArray<NSNumber*>* messagesWhilePresenting;

@property (nonatomic,strong) MediaDevice *lastRenderingDevice;

@end

@implementation DLNAHomeManager

+(instancetype)shared
{
    static DLNAHomeManager *shared = nil;
    if (shared == nil) {
        shared = [[DLNAHomeManager alloc] initPrivate];
    }
    
    return shared;
}

-(instancetype)initPrivate
{
    self = [super init];
    if (self) {
        
        [self setup];

        
    }
    return self;
}





-(void)setup
{
    static bool first = true;
    
    if (first) {
        first = false;
        
        rendererPresenting = true;
        
        initPlayerMessage();
        
        [[UPnPCenter shared] addDeviceServer];
        [[UPnPCenter shared] addDeviceRenderer];
        [[UPnPCenter shared] addCtrlPoint];
        [[UPnPCenter shared] startUpnp];
        
        //Init Renderer
        [[DlnaRender shared] addActionListener:self];
        [[DlnaControlPoint shared] addListener: self];
        
        
        self.messagesWhilePresenting = [NSMutableArray array];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackgournd) name:UIApplicationDidEnterBackgroundNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillTerminate) name:UIApplicationWillTerminateNotification object:nil];
    }
    
}

-(void)appWillTerminate
{
    [[UPnPCenter shared] stopUpnp];
}

-(void)appDidEnterBackgournd
{
    UIApplication *application = [UIApplication sharedApplication];
    bgTask = [application beginBackgroundTaskWithName:@"MyTask" expirationHandler:^{
        
        // stop dlna
        [[UPnPCenter shared] stopUpnp];
        
        [application endBackgroundTask:bgTask];
        
        bgTask = UIBackgroundTaskInvalid;
    }];
}

-(void)appWillEnterForeground
{
    [[UPnPCenter shared] startUpnp];
}

-(void)eventComing:(event_name)event_type from:(DlnaControlPoint *)ctrlPoint
{
    if (event_type == event_user_opened_resource)
    {
        if (self.delegate) {
            [self.delegate newRendererConnected: self];
        }
        
    }
    
}


-(void)actionComing:(DLNAActionType)type from:(MediaPanelN2H *)controller
{
    if (type == setAVTransportURI)
    {
        if ( controller.avTransportURL ) {
            [[NSNotificationCenter defaultCenter] postNotificationName: kNotifyPresentModal object: nil];
            
            [self startPresentRenderer];
            
            if (rendererPresenting) {
                NSLog(@"collection event: %lu",(unsigned long)type);
                
                NSNumber *number = [NSNumber numberWithInteger:type];
                [self.messagesWhilePresenting addObject:number];
            }
            
            [self.delegate dlnaManagerNeedPresentRenderer:self ];
        }
        else{
           
            
            [self.delegate dlnaManagerNeedDismissRenderer:self];
        }
        
    }
    else{
        if (rendererPresenting) {
            NSLog(@"collection event: %lu",(unsigned long)type);
            
            NSNumber *number = [NSNumber numberWithInteger:type];
            [self.messagesWhilePresenting addObject:number];
        }
    }
    
    
    
}



-(void)startPresentRenderer
{
    rendererPresenting = true;
}

-(void)endPresentRenderer
{
    rendererPresenting = false;
    
    [self.messagesWhilePresenting removeAllObjects];
    NSLog(@"collection remove all messages.");
}

-(void)pickMissingActionMessages:(id<DLNAActionListener>)picker
{
    for ( NSNumber *number in self.messagesWhilePresenting) {
        DLNAActionType type = (DLNAActionType)number.integerValue;
        
        [picker actionComing:type from: [DlnaRender shared].controller];
    }
    
}
@end
