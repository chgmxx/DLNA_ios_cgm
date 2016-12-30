//
//  UPnPCenter.m
//  DLNASample
//
//  Created by liaogang on 16/11/18.
//  Copyright © 2016年 liaogang. All rights reserved.
//

#import "UPnPCenter.h"
#import "DlnaRender.h"
#import "DlnaControlPoint.h"
#import "UPnPEngine.h"


@interface DlnaControlPoint (plt)
-(PLT_CtrlPointReference)getInner;
@end

@interface DlnaRender (plt)
-(PLT_DeviceHostReference)getInner;
@end

@interface UPnPEngine (plt)
-(PLT_DeviceHostReference)getInner;
@end





NSString *kKeyRenderEnabled = @"DlnaRender_enabled";
NSString *kKeyDMS_enabled = @"Dlna_DMS_enabled";

@interface UPnPCenter ()
@end

@implementation UPnPCenter


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
    //Register renderer and server default enabled.
    NSDictionary *defaults = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithBool:YES], kKeyRenderEnabled,
                              [NSNumber numberWithBool:YES], kKeyDMS_enabled,
                              nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults: defaults];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    
    // Wifi change.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(localWiFiChanged:) name:kReachabilityChangedNotification object:nil];
        
    _reachability = [Reachability reachabilityForLocalWiFi];
    [self.reachability startNotifier];
    
    
    // Create upnp engine
    _pUpnp = new PLT_UPnP;
    _pUpnp->SetIgnoreLocalUUIDs(false);


//    if ( self.reachability.currentReachabilityStatus == ReachableViaWiFi) {
//        _pUpnp->Start();
//    }
    
}

+(instancetype)shared
{
    static UPnPCenter *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[UPnPCenter alloc] initPrivate];
    });

    return shared;
}


-(void)localWiFiChanged:(NSNotification*)n
{
    Reachability *r = n.object;
    auto result = r.currentReachabilityStatus;
    
    NSLog(@"localWiFiChanged");
    
    static NSInteger lastStatus =  -1;
    
    if (result != lastStatus) {
        if( result != NotReachable)
        {
            NSLog(@"start upnp");
            [self startUpnp];
        }
        else
        {
            NSLog(@"stop upnp");
            [self stopUpnp];
        }
        
        lastStatus = result;
    }
    
}


-(void)stopUpnp
{
    _pUpnp->Stop();
}

-(void)startUpnp
{
    if (_pUpnp->IsRunning() == false) {
        _pUpnp->Start();
        [[DlnaControlPoint shared] startSearchDevices];
    }
    
}

-(void)addDeviceRenderer
{
    auto device = [[DlnaRender shared] getInner];
    _pUpnp->AddDevice( device );
}

-(void)addDeviceServer
{
    auto device = [[UPnPEngine getEngine ] getInner];
    _pUpnp->AddDevice( device );
}

-(void)addCtrlPoint
{
    auto cp =[[DlnaControlPoint shared] getInner];
    _pUpnp->AddCtrlPoint( cp );
}

-(void)removeDeviceRenderer
{
    auto device = [[DlnaRender shared] getInner];
    _pUpnp->RemoveDevice( device );
}

-(void)removeDeviceServer
{
    auto device = [[UPnPEngine getEngine ] getInner];
    _pUpnp->RemoveDevice( device );
}

-(void)removeCtrlPoint
{
    auto cp =[[DlnaControlPoint shared] getInner];
    _pUpnp->RemoveCtrlPoint( cp );
}

-(void)disableRenderer
{
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey: kKeyRenderEnabled];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)enableRenderer
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey: kKeyRenderEnabled];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(bool)isRendererEnabled
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kKeyRenderEnabled];
}

-(void)disableServer
{
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey: kKeyDMS_enabled];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)enableServer
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey: kKeyDMS_enabled];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(bool)isServerEnabled
{
    return [[NSUserDefaults standardUserDefaults] boolForKey: kKeyDMS_enabled];
}

@end
