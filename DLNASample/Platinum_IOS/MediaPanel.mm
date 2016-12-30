//
//  MediaPanel.m
//  demo
//
//  Created by liaogang on 15/6/30.
//  Copyright (c) 2015年 com.cs. All rights reserved.
//

#import "MediaPanel.h"
#import "CellDataB.h"


void read_from_state_variable(MediaPanel *mediaPanel, NPT_List<PLT_StateVariable*>* vars);

const char * kStrPlayState[] = {
    "NO_MEDIA_PRESENT",
    "PLAYING",
    "STOPPED",
    "PAUSED_PLAYBACK"
};


@implementation MediaPanel

-(void)setVolume:(unsigned int)volume
{
    NSAssert(0 <= volume && volume <= 100, nil);
    _volume = volume;
}

@end



@implementation MediaPanelH2N

-(void)write_drity:(PLT_MediaRendererMy*)renderer
{
    renderer->MediaChanged( self );
}
@end

@interface MediaPanelN2H ()
@property (nonatomic,strong) CellDataA *currentURIMetaDataItem;
@end

@implementation MediaPanelN2H

-(instancetype)initWithPLT_ActionReference:(PLT_ActionReference*)action
{
    self = [super init];
    if (self)
    {
        NPT_String currentURI;
        (*action)->GetArgumentValue("CurrentURI", currentURI);
        
        if ( currentURI.GetLength() == 0)
        {
            self.avTransportURL = nil;
        }
        else{
            self.avTransportURL = [NSString stringWithUTF8String: currentURI];
        }
        
        NSLog(@" av transport url: %@",_avTransportURL);
        
        NPT_String currentURIMetaData;
        (*action)->GetArgumentValue("CurrentURIMetaData", currentURIMetaData);
        
        PLT_MediaObjectListReference medias;
        PLT_Didl::FromDidl(currentURIMetaData, medias);
        
        
        if (!medias.IsNull())
        {
            int count = medias->GetItemCount();
            if (count > 0)
            {
                auto it = medias->GetFirstItem();
                PLT_MediaObject *media = *it;
                
                self.currentURIMetaDataItem = [[CellDataA alloc] initWithMediaObject:media];
 
                const int table_MediaType_2_DlnaUrlType[] = {
                    DlnaUrlType_unsupport,
                    DlnaUrlType_video,
                    DlnaUrlType_unsupport,
                    DlnaUrlType_photo,
                    DlnaUrlType_music,
                    DlnaUrlType_unsupport
                };
               
                self.mediaType = (DlnaUrlType) table_MediaType_2_DlnaUrlType[(int)[self.currentURIMetaDataItem getType]];
                
            }
        }
        
        
    }
    
    return self;
}

-(CellDataA*)getURIMedaData
{
    return self.currentURIMetaDataItem;
}

-(void)udpate_from:(NPT_List<PLT_StateVariable*>* )vars
{
    read_from_state_variable(self, vars);
}

-(void)update_from_positionInfo:(PLT_PositionInfo*)position
{
    self.currentTime = position->rel_time.ToSeconds();
    
    self.duration = position->track_duration.ToSeconds();
}

-(void)read_seek_action:(PLT_ActionReference*)action
{
    NPT_String uint;
    NPT_String target;
    
    (*action)->GetArgumentValue("Unit", uint);
    (*action)->GetArgumentValue("Target", target);
    
    if (uint.Compare("REL_TIME") == 0)
    {
        self.seekSecond = dlna_string_to_second(target);
    }
    else
    {
        printf("Unsupportted argument value.\n");
    }
    
}
@end


const char *dlna_second_to_stirng(int sec)
{
    static char arg[256];
    memset(arg, 0, 256 * sizeof(char) );
    
    if (sec > 0)
    {
        int v = sec;
        int h = v / (60*60);
        int m = (v - h * 60 * 60 ) / 60;
        int s = (v - m * 60 - h*60*60);
        
        assert( h >= 0 && s < 60 && m < 60);
        
        sprintf(arg, "%02d:%02d:%02d", h , m , s);
    }
    else
    {
        strcpy(arg, "00:00:00");
    }

    
    return arg;
}


int dlna_string_to_second(const char *format)
{
    int h=0,m=0,s=0;
    
    sscanf(format,"%d:%02d:%02d",&h,&m,&s);
    
    assert( h >= 0 && s < 60 && m < 60);

    return (h * 60 + m ) * 60 + s;
}

void write_to_state_variable(MediaPanel *mediaPanel,PLT_Service *serviceAVTransport,PLT_Service *serviceRenderingControl)
{
    char volume[5] = {0};
    sprintf(volume, "%d" , mediaPanel.volume);
    serviceRenderingControl->SetStateVariable("Volume", volume);
    
    serviceRenderingControl->SetStateVariable("Mute", mediaPanel.mute?"1":"0" );
    
    
    const char *s;
    
    s = dlna_second_to_stirng( mediaPanel.currentTime );
    serviceAVTransport->SetStateVariable("RelativeTimePosition", s );
    
    s = dlna_second_to_stirng( mediaPanel.duration );
    serviceAVTransport->SetStateVariable("CurrentTrackDuration", s );
    
    
    serviceAVTransport->SetStateVariable("TransportState", kStrPlayState[mediaPanel.playState] );
}

void read_from_state_variable(MediaPanel *mediaPanel, NPT_List<PLT_StateVariable*>* vars)
{
    NPT_List<PLT_StateVariable*>::Iterator var = vars->GetFirstItem();
    while (var)
    {
        NPT_String name = (*var)->GetName();
        NPT_String value = (*var)->GetValue();
        
        if ( name.Compare("Volume" ,true) == 0) {
            
            unsigned int volume = 0;
            
            sscanf( (*var)->GetValue(), "%ud" , &volume);
            
            mediaPanel.volume =  volume;
            
        }
        else if (name.Compare("Mute",true) == 0)
        {
            mediaPanel.mute = value == "1" ? TRUE : FALSE;
        }
        else if (name.Compare("TransportState",true) == 0 )
        {
            if ( value == kStrPlayState[PlayState_stopped] ) {
                mediaPanel.playState = PlayState_stopped;
            }
            else if (value == kStrPlayState[PlayState_playing] )
            {
                mediaPanel.playState = PlayState_playing;
            }
            else if ( value == kStrPlayState[PlayState_paused] )
            {
                mediaPanel.playState = PlayState_paused;
            }
            else if (value == kStrPlayState[PlayState_unknown] )
            {
                mediaPanel.playState = PlayState_unknown;
            }
            
        }
        
        
        ++var;
    }
    
}

