//
//  DlnaControlPoint.mm
//  demo
//
//  Created by liaogang on 15/6/10.
//  Copyright (c) 2015年 com.cs. All rights reserved.
//

#import "DlnaControlPoint.h"
#import <UIKit/UIKit.h>
#import "Reachability.h"
#import "CellDataB.h"
#import "PltMicroMediaController.h"
#import "MediaPanel.h"

void eventHandler(enum event_name eventName,void *result,void* event_custom_data);

@interface MediaDevice ()
@property (nonatomic) PLT_DeviceDataReference inner;
-(instancetype)initWithPLT_DeviceDataReference:(PLT_DeviceDataReference)device;
@end


@interface DlnaControlPoint ()
{
    dispatch_source_t	_timer;
    NSInteger openedMediaIndex;
    PLT_CtrlPointReference _ctrlPointRF;
}

@property (nonatomic,readonly,assign) PLT_MicroMediaController *inner;

-(void)eventHandler:(enum event_name)eventName :(void *)result;

@property (nonatomic,strong) NSMutableArray<id<ControlPointEventListener>> * listeners;

@property (nonatomic,strong) NSMutableArray< NSArray<CellDataA*> *> * browsingStack;

@end


@implementation DlnaControlPoint

-(PLT_CtrlPointReference)getInner
{
    return _ctrlPointRF;
}

-(NSArray<CellDataA*> *)getBrowsing
{
    return _browsingStack.lastObject;
}

-(void)eventHandler:(enum event_name)eventName :(void *)result
{
    if (self.listeners.count > 0)
    {
        switch (eventName) {
            case event_rendering_control_response:
            {
                eventDataRenderControlResponse *d = (eventDataRenderControlResponse*)result;
                [self renderingControlResponse: d];
                break;
            }
            case event_state_variables_changed:
            {
                eventDataStateVariables *d = (eventDataStateVariables*)result;
                
                [self MRStateVariablesChanged:d];
                
                break;
            }
            case event_render_list_changed:
            {
                PLT_DeviceArray deviceArray = self.inner->GetRenderDevices();
                
                NSMutableArray<MediaDevice*> * ocRenderers = [NSMutableArray array];
                
                bool finded = false;
                
                int count = deviceArray.GetItemCount();
                for (int i = 0; i < count; i++) {
                    PLT_DeviceDataReference device = deviceArray[i];
                    MediaDevice *ocDevice = [[MediaDevice alloc]initWithPLT_DeviceDataReference: device];
                    
                    if ([ocDevice isEqual: _currentRenderer]) {
                        finded = true;
                    }
                    
                    [ocRenderers addObject:ocDevice];
                }
                
                _renderers = ocRenderers;
                
                
                //Check if our selected renderer is changed.
                if (!finded) {
                    _currentRenderer = nil;
                }
                
                
                break;
            }
            case event_media_server_list_changed:
            {
                // fill server lists
                PLT_DeviceArray deviceArray = self.inner->GetServerDevices();
                
                NSMutableArray<MediaDevice*> * ocServers = [NSMutableArray array];
                
                // find if current browsing device is still there.
                bool finded = false;
                
                int count = deviceArray.GetItemCount();
                for (int i = 0; i < count; i++) {
                    PLT_DeviceDataReference device = deviceArray[i];
                    MediaDevice *ocDevice = [[MediaDevice alloc]initWithPLT_DeviceDataReference: device];
                    [ocServers addObject:ocDevice];
                    
                    if ( [self.currentServer isEqual: ocDevice] ) {
                        finded = true;
                    }
                }
                
                _servers = ocServers;
                
                
                if (!finded) {
                    _currentServer = nil;
                    [self cmd_cd_root];
                    //notify the client, is removed.
                }

                break;
            }
            default:
                break;
        }
        
        
        
        for ( id<ControlPointEventListener> listener in self.listeners) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [listener eventComing:eventName from:self];
            });
            
        }
        
    }
}

+(instancetype)shared
{
    static DlnaControlPoint *sharedDlnaControlPoint = nil;

    if (sharedDlnaControlPoint == nil) {
        sharedDlnaControlPoint = [[DlnaControlPoint alloc]initPrivate];
    }
    
    return sharedDlnaControlPoint;
}


-(void)addListener:(id<ControlPointEventListener>) listener
{
    [self.listeners addObject:listener];
}

-(void)startSearchDevices
{
    _inner->startSearchDevices();
}

-(void)setup
{
    self.browsingStack = [NSMutableArray array];
    _render = [[MediaPanelN2H alloc]init];
    self.listeners = [NSMutableArray array];
    

    // setup Neptune logging
    {
        NPT_LogManager::GetDefault().SetEnabled(false);
//        NPT_LogManager::GetDefault().Configure("plist:.level=FINE;.handlers=ConsoleHandler;.ConsoleHandler.colors=off;.ConsoleHandler.filter=24");

        
        // Create control point
        _ctrlPointRF = PLT_CtrlPointReference(new PLT_CtrlPoint());
        
        // Create controller
        _inner = new PLT_MicroMediaController ( _ctrlPointRF );
        
        _inner->setEventNotifyHandler(eventHandler, (__bridge void*)self);
        
        _inner->startSearchDevices();
    }
    
    
    
#ifdef BROADCAST_EXTRA
    // tell control point to perform extra broadcast discover every 6 secs
    // in case our device doesn't support multicast
    ctrlPoint->Discover(NPT_HttpUrl("255.255.255.255", 1900, "*"), "upnp:rootdevice", 1, 6000);
    ctrlPoint->Discover(NPT_HttpUrl("239.255.255.250", 1900, "*"), "upnp:rootdevice", 1, 6000);
#endif
    
    
    // Update the UI 3 times per second
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(_timer, DISPATCH_TIME_NOW, NSEC_PER_SEC / 2, NSEC_PER_SEC / 3);
    
    dispatch_source_set_event_handler(_timer, ^{
        if (_render.playState == PlayState_playing) {
            _inner->HandleCmd_getPositionInfo();
        }
    });
    
    // Start the timer
    dispatch_resume(_timer);
}

-(instancetype)initPrivate
{
    self = [super init];
    if (self) {
        [self setup];
        
    }
    
    return self;
}

-(void)dealloc
{
    if (_inner)
        delete _inner;
}



-(void)MRStateVariablesChanged:(eventDataStateVariables*)d
{
    [self.render udpate_from: (NPT_List<PLT_StateVariable*>*)d ];
    
    
    //read_from_state_variable(_render, (NPT_List<PLT_StateVariable*>*)d);
    /*
    if(_renderMediaStateChanged)
    {
        MediaPanel*  mp = [[MediaPanel alloc]init];
        
        mp.trackPosition = _render.trackPosition ;
        mp.trackDuration = _render.trackDuration ;
        mp.playState = _render.playState ;
        
//        if (mp.playState == PlayState_stopped) {
//            self.inner->clearPlayingMediaTitle();
//        }
        
        mp.volume = _render.volume;
        mp.mute = _render.mute;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            _renderMediaStateChanged(mp);
        });
    }
    */
    
    for ( id<ControlPointEventListener> listener in self.listeners) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [listener eventComing:event_state_variables_changed from:self];
        });
    }
    
}

-(void)renderingControlResponse:(eventDataRenderControlResponse*)d
{
    const char *name = d->actionName;
    void* result = d->result;
    
    if (!result) {
        return;
    }
    
    if ( strcmp(name,"GetVolume") == 0) {
        NPT_UInt32	volume;
        volume = *(NPT_UInt32*)result;
        
        _render.volume = volume;
        
        
        for ( id<ControlPointEventListener> listener in self.listeners) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [listener eventComing:event_state_variables_changed from:self];
            });
        }
        
    }
    else if ( strcmp(name,"GetPositionInfo") == 0) {
        PLT_PositionInfo* info = (PLT_PositionInfo*)result;
        
        [_render update_from_positionInfo:info];
        
       
        for ( id<ControlPointEventListener> listener in self.listeners) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [listener eventComing:event_rendering_control_response from:self];
            });
        }
        
    }
    else if ( strcmp(name,"GetMute") == 0) {
        bool mute = *(bool*)result;
        
        _render.mute = mute;
        
        for ( id<ControlPointEventListener> listener in self.listeners) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [listener eventComing:event_state_variables_changed from:self];
            });
        }
    }
    
    
}

-(void)cmd_cdup
{
    self.inner->HandleCmd_cdup();
    
    [self.browsingStack removeLastObject];
}

-(void)cmd_cd_root
{
    self.inner->PopDirectoryStackToRoot();
    [_browsingStack removeAllObjects];
}


// get current directory data
-(void)cmd_ls
{
    PLT_MediaObjectListReference files = self.inner->ls();
    if (!files.IsNull())
    {
        NSMutableArray *result = [NSMutableArray array];
        for ( int i = 0 ; i < files->GetItemCount(); i++  )
        {
            auto it =   files->GetItem(i);
            PLT_MediaObject* file = *it;
            
            [result addObject: [[CellDataA alloc] initWithMediaObject:file]];
           
        }
        
        
        [_browsingStack addObject:result];
    }
    else
    {
        [_browsingStack addObject: [NSArray array] ];
    }
    
}

-(void)cmd_cd:(NSUInteger)index
{
    CellDataA *data = self.browsing[index];
    
    assert([data getType] == Folder);
    
    NSString *cmd = [NSString stringWithFormat:@"cd %@", [data getObjectID] ];
    
    NSLog(@"change directory: %@",[data getTitle]);
    
    
    self.inner->HandleCmd_cd( cmd.UTF8String );
}

-(bool)openIndex:(NSUInteger)index
{
    openedMediaIndex = _inner->openIndex((int)index);
    
    if (openedMediaIndex != -1) {
        for ( id<ControlPointEventListener> listener in self.listeners) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [listener eventComing:event_user_opened_resource from:self];
            });
        }
    }
    
    return openedMediaIndex != -1;
}

-(CellDataA* _Nullable)getOpenedMedia
{
    return  self.browsing[openedMediaIndex];
}

-(NSInteger)getOpenedMediaIndex
{
    return openedMediaIndex;
}


-(void)chooseServer:(NSUInteger)index
{
    _currentServer = self.servers[index];
    
    _inner->ChooseDeviceWithUUID([_currentServer GetUUID].UTF8String);
}

-(void)chooseRenderer:(NSUInteger)index
{
    _inner->selectMR((int)index);
    _currentRenderer = self.renderers[index];
    
    assert( [_currentRenderer isEqual: [self GetCurrentMediaRenderer]]);
    
    
    
    for ( id<ControlPointEventListener> listener in self.listeners) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [listener eventComing:event_user_choosed_renderer from:self];
        });
    }
    
}

-(MediaDevice* _Nullable)GetCurrentMediaRenderer
{
    PLT_DeviceDataReference device;
    _inner->GetCurMediaRenderer(device);
    if (device.IsNull())
    {
        return nil;
    }
    else{
        return [[MediaDevice alloc]initWithPLT_DeviceDataReference:device];
    }
    
}



-(void)cmd_play
{
    _inner->HandleCmd_play();
}

-(void)cmd_pause
{
    _inner->HandleCmd_pause();
}

-(void)cmd_seek:(NSUInteger)second
{
    int v = (int)second;
    int h = v/(60*60);
    int m = (v - h * 60*60)/60;
    int s = (v - m * 60);
    char arg[256];
    sprintf(arg, "seek %2d:%2d:%2d", h , m , s);
    _inner->HandleCmd_seek(arg);
}

-(void)cmd_stop
{
    _inner->HandleCmd_stop();
}
-(void)cmd_mute
{
    _inner->HandleCmd_mute();
}
-(void)cmd_unmute
{
    _inner->HandleCmd_unmute();
}

-(void)cmd_setVolumn:(NSUInteger)volume
{
    
}

@end



void eventHandler(enum event_name eventName,void *result,void* event_custom_data)
{
    DlnaControlPoint *cp = (__bridge DlnaControlPoint*)event_custom_data;
    [cp eventHandler:eventName :result];
}


