//
//  DlnaRender.mm
//  demo
//
//  Created by liaogang on 15/6/30.
//  Copyright (c) 2015年 com.cs. All rights reserved.
//

#import "DlnaRender.h"
#import <UIKit/UIKit.h> //UIDevice name
#import "MAAssert.h"
#import "MediaPanel.h"


NSString *kNotifyDMRStopped = @"dmr_stopped";

NSString *kNotifyDMRStarted = @"dmr_started";

PLT_MediaRendererMy::PLT_MediaRendererMy(const char*  friendly_name,
                                         bool         show_ip ,
                                         const char*  uuid ,
                                         unsigned int port ,
                                         bool         port_rebind ):PLT_MediaRenderer(friendly_name,show_ip,uuid,port,port_rebind)
{
}

void PLT_MediaRendererMy::MediaChanged(MediaPanel *media)
{
    write_to_state_variable(media, _serviceAVTransport, _serviceRenderingControl);
}

NPT_Result PLT_MediaRendererMy::SetupServices()
{
    PLT_MediaRenderer::SetupServices();
    
    // export some service to change.
    _serviceAVTransport = nullptr;
    _serviceRenderingControl = nullptr;
    _serviceConnectionManager = nullptr;
    
    NPT_Array<PLT_Service*> services = GetServices();
    int c = services.GetItemCount();
    for (int i = 0; i < c; i++) {
        PLT_Service *s = services[i];
        NPT_String sid = s->GetServiceID();
        if ( sid.Compare("urn:upnp-org:serviceId:AVTransport",true) == 0)
        {
            _serviceAVTransport = s;
        }
        else if( sid.Compare("urn:upnp-org:serviceId:RenderingControl",true) == 0)
        {
            _serviceRenderingControl = s;
        }
        else if ( sid.Compare("urn:upnp-org:serviceId:ConnectionManager",true) == 0)
        {
            _serviceConnectionManager = s;
        }
    }
    
    if (_serviceConnectionManager)
    {
        // Add support of some media format
        NPT_String sinkProtocalInfo;
        _serviceConnectionManager->GetStateVariableValue("SinkProtocolInfo",sinkProtocalInfo);
        
        sinkProtocalInfo.Append(
                                ",http-get:*:video/quicktime:*"
                                ",http-get:*:video/mp4:*"
                                ",http-get:*:application/vnd.rn-realmedia-vbr:*"
                                ",http-get:*:image/png:DLNA.ORG_PN=PNG_LRG"
                                ",http-get:*:image/tiff:DLNA.ORG_PN=TIFF_LRG"
                                ",http-get:*:image/gif:DLNA.ORG_PN=GIF_LRG"
                                ",http-get:*:audio/mp4:DLNA.ORG_PN=AAC_ISO;DLNA.ORG_OP=01;DLNA.ORG_CI=0;DLNA.ORG_FLAGS=01500000000000000000000000000000"
                                ",http-get:*:audio/wav:*"
                                );
        
        _serviceConnectionManager->SetStateVariable("SinkProtocolInfo", sinkProtocalInfo);
    }
    else
    {
        printf("can not find `urn:upnp-org:serviceId:ConnectionManager`\n");
    }
    
    return NPT_SUCCESS;
}



@interface DlnaRender () <MediaRendererDelegate>
{
    PLT_MediaRendererDelegateMy delegateCPP;
    PLT_MediaRendererMy *pRenderer;
    PLT_DeviceHostReference rDevice;
}

@property (nonatomic,strong) NSMutableArray<id<DLNAActionListener>> *listeners;

@end


@implementation DlnaRender
-(PLT_DeviceHostReference)getInner
{
    return rDevice;
}

+(instancetype)shared
{
    static DlnaRender *shared = nil;
    
    if (shared == nil) {
        shared = [[DlnaRender alloc]init];
    }
    
    return shared;
}

-(instancetype)init
{
    self  = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

-(void)addActionListener:(id<DLNAActionListener>) listener
{
    __weak id<DLNAActionListener> tmp = listener;
    [self.listeners addObject: tmp ];
}

-(void)removeActionListener:(id<DLNAActionListener>)listener
{
    [self.listeners removeObject:listener];
}

-(void)setup
{
    self.listeners = [NSMutableArray array];
    
    if (!_mydirty) {
        _mydirty = [[MediaPanelH2N alloc]init];
        _controller = [[MediaPanelN2H alloc]init];
    }

    // Setup a media renderer.
    pRenderer = new PLT_MediaRendererMy([[UIDevice currentDevice] name].UTF8String, false);
    pRenderer->SetByeByeFirst(false);
    pRenderer->SetDelegate(&delegateCPP);
    delegateCPP.owner = self;
    
    
    rDevice = PLT_DeviceHostReference ( pRenderer);
    rDevice->m_ModelDescription = "Genie Media Render";
    
    
    //Add device icon.
    UIImage *serverImage = [UIImage imageNamed:@"genie_dlna_server"];
    if (serverImage) {
        NSData* data =  UIImagePNGRepresentation(serverImage);
        PLT_DeviceIcon icon("image/png",152,152,32,"/genie_dlna_server.png");
        rDevice->AddIcon(icon, data.bytes , (NPT_Size)data.length );
    }else{
        NSLog(@"render icon not finded.");
    }
    
}

-(PLT_DeviceDataReference)getDevice
{
    return rDevice;
}

#pragma mark - MediaRendererDelegate

-(void)OnGetCurrentConnectionInfo:(PLT_ActionReference*)action
{

    
}

// AVTransport
-(void) OnNext:(PLT_ActionReference*)action
{
    for ( id<DLNAActionListener> listener in self.listeners) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [listener actionComing: Next from: _controller];
        });
    }

}

-(void) OnPause:(PLT_ActionReference*)action
{
    for ( id<DLNAActionListener> listener in self.listeners) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [listener actionComing: Pause from: _controller];
        });
    }
}

-(void) OnPlay:(PLT_ActionReference*)action
{
    for ( id<DLNAActionListener> listener in self.listeners) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [listener actionComing: Play from: _controller];
        });
    }
}

-(void) OnPrevious:(PLT_ActionReference*)action
{
    for ( id<DLNAActionListener> listener in self.listeners) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [listener actionComing: Previous from: _controller];
        });
    }
}

-(void) OnSeek:(PLT_ActionReference*)action
{
    [self.controller read_seek_action: action ];
    
    for ( id<DLNAActionListener> listener in self.listeners) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [listener actionComing: Seek from: _controller];
        });
    }
}

-(void) OnStop:(PLT_ActionReference*)action
{
    for ( id<DLNAActionListener> listener in self.listeners) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [listener actionComing: Stop from: _controller];
        });
    }
    
}

-(void) OnSetAVTransportURI:(PLT_ActionReference*)action
{
    self.controller = [[MediaPanelN2H alloc] initWithPLT_ActionReference:action];
    
    for ( id<DLNAActionListener> listener in self.listeners) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [listener actionComing: setAVTransportURI from: _controller];
        });
    }
    
}

-(void) OnSetPlayMode:(PLT_ActionReference*)action
{
    
    for ( id<DLNAActionListener> listener in self.listeners) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [listener actionComing: setPlayMode from: _controller];
        });
    }
}

// RenderingControl
-(void) OnSetVolume:(PLT_ActionReference*)action
{
    NPT_UInt32 volume = 0;
    (*action)->GetArgumentValue("DesiredVolume", volume);
    
    self.controller.volume = volume;
    
    
    for ( id<DLNAActionListener> listener in self.listeners) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [listener actionComing: setVolume from: _controller];
        });
    }
}

-(void) OnSetVolumeDB:(PLT_ActionReference*)action
{
}

-(void) OnGetVolumeDBRange:(PLT_ActionReference*)action
{
}

-(void) OnSetMute:(PLT_ActionReference*)action
{
    NPT_String mute;
    (*action)->GetArgumentValue("DesiredMute",mute);
    
    bool bMute = ( mute == "1" );
    
    self.controller.mute = bMute;
    
    
    
    
    for ( id<DLNAActionListener> listener in self.listeners) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [listener actionComing: Mute from: _controller];
        });
    }
}

-(void)notifyDirty
{
    [_mydirty write_drity: pRenderer];
}

@end
