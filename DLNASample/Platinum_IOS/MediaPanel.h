//
//  MediaPanel.h
//  demo
//
//  Created by liaogang on 15/6/30.
//  Copyright (c) 2015年 com.cs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Platinum/Platinum.h>
#import "CellDataA.h"
#import "DlnaRender.h"









/**
 表示DMPlayer状态
 */
@interface MediaPanel : NSObject

/**
 volume level is defined as an integer number between 0 and 100.
 @see <<DLNA Architecture>>17.2.7
 */
@property (nonatomic,assign) unsigned int volume;

/// "1"静音,"0"没有静音
@property (nonatomic,assign) BOOL mute;

/** Time Format : H+:MM:SS[.F+] or H+:MM:SS[.F0/F1]
    @see http://www.upnp.org/specs/av/UPnP-av-AVTransport-v3-Service-20101231.pdf  2.2.15
    `AbsoluteTimePosition` is not used in the DLNA context. So use `RelativeTimePosition` instead.
    @see <<DLNA architecture>> 14.2.2 and 14.2.24
 
 */
//@property (nonatomic,strong) NSString *trackPosition,*trackDuration;
@property (nonatomic) NSTimeInterval currentTime,duration;

@property (nonatomic) enum PlayState2 playState;

@end

int dlna_string_to_second(const char *format);

const char *dlna_second_to_stirng(int sec);


typedef enum : NSUInteger {
    DlnaUrlType_unsupport = 0,
    DlnaUrlType_video = 0x0001,
    DlnaUrlType_photo = 0x0010,
    DlnaUrlType_music = 0x0100,
} DlnaUrlType;

/** Read status from network to host
 */
@interface MediaPanelN2H : MediaPanel

-(instancetype)initWithPLT_ActionReference:(PLT_ActionReference*)action;

-(CellDataA*)getURIMedaData;

@property (nonatomic) NSString *avTransportURL;

@property (nonatomic) DlnaUrlType mediaType;

// Subscribe state variable changed
-(void)udpate_from:(NPT_List<PLT_StateVariable*>* )vars;

-(void)update_from_positionInfo:(PLT_PositionInfo*)position;

-(void)read_seek_action:(PLT_ActionReference*)action;
@property (nonatomic) int seekSecond;

@end

/** Write host render status to network
 */
@interface MediaPanelH2N : MediaPanel

-(void)write_drity:(PLT_MediaRendererMy*)renderer;

@end



void write_to_state_variable(MediaPanel *mediaPanel,PLT_Service *serviceAVTransport,PLT_Service *serviceRenderingControl);
