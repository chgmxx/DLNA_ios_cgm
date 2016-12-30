//
//  PlatinumIOSConst.h
//  DLNASample
//
//  Created by liaogang on 16/11/24.
//  Copyright © 2016年 liaogang. All rights reserved.
//

#ifndef PlatinumIOSConst_h
#define PlatinumIOSConst_h

enum event_name
{
    event_render_list_changed,
    event_media_server_list_changed,
    
    // "GetPositionInfo"  response
    event_rendering_control_response,
    
    // renderer state changed
    event_state_variables_changed,
    
    event_user_opened_resource,
    event_user_choosed_renderer,
};


enum PlayState2
{
    PlayState_unknown = 0,
    PlayState_playing,
    PlayState_stopped,
    PlayState_paused,
};

/// @see http://upnp.org/specs/av/UPnP-av-AVTransport-v1-Service.pdf ,Table 1.1
extern const char * kStrPlayState[];

typedef enum
{
    setAVTransportURI,
    Play,
    Pause,
    Stop,
    Seek,
    Next,
    Previous,
    setPlayMode,
    setVolume,
    Mute,
} DLNAActionType;




#endif /* PlatinumIOSConst_h */
