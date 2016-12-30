//
//  DlnaControlPoint.h
//  demo
//
//  Created by liaogang on 15/6/10.
//  Copyright (c) 2015年 com.cs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PlatinumIOSConst.h"
#import "CellDataA.h"

@protocol ControlPointEventListener;

@class CellDataA,MediaPanelN2H;
/**  
 A DLNA Control pointer manager
 
 1. Media Server  ==> Control Point ==>   Media Render
 2: Receive state from Media Render
 */
@interface DlnaControlPoint : NSObject

///use the shared instance
-(instancetype _Nullable)init NS_UNAVAILABLE;

+(instancetype _Nonnull)shared;

-(void)startSearchDevices;

///the browsing data is change by command cdup,cd...
@property (nonatomic,strong,readonly,getter=getBrowsing) NSArray<CellDataA* > * _Nullable browsing ;

@property (nonatomic,strong,readonly) NSArray<MediaDevice*> * _Nullable servers,*_Nullable renderers;

/// current browsing source or rendering renderer var `chooseServer` or `chooseRenderer`.
@property (nonatomic,strong,readonly) MediaDevice * _Nullable currentServer,*_Nullable currentRenderer;

-(void)chooseServer:(NSUInteger)index;
-(void)chooseRenderer:(NSUInteger)index;

-(void)cmd_cdup;
-(void)cmd_cd_root;

///change the directory
-(void)cmd_cd:(NSUInteger)index;

/// get current directory data
-(void)cmd_ls;

///select a resource and send to Render var `setAVTransportURI`
///return wether the command is sended.
-(bool)openIndex:(NSUInteger)index;

-(CellDataA* _Nullable)getOpenedMedia;
-(NSInteger)getOpenedMediaIndex;


//once a media is select opened to send to renderer,we can send control command.
-(void)cmd_play;
-(void)cmd_pause;
-(void)cmd_seek:(NSUInteger)second;
-(void)cmd_stop;
-(void)cmd_mute;
-(void)cmd_unmute;
-(void)cmd_setVolumn:(NSUInteger)volume;


-(void)addListener:(id<ControlPointEventListener> _Nonnull) listener;

// the status of current render we controlling. 
@property (nonatomic,readonly) MediaPanelN2H *_Nonnull render;

@end


@protocol ControlPointEventListener <NSObject>

-(void)eventComing:(enum event_name)event_type from:(DlnaControlPoint* _Nonnull)ctrlPoint;

@end
