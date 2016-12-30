//
//  DLNAHomeViewController.h
//  iDLNA
//
//  Created by liaogang on 16/11/16.
//  Copyright © 2016年 liaogang. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DLNAHomeManagerDelegate;
@protocol DLNAActionListener;

@interface DLNAHomeManager : NSObject

+(instancetype)shared;

-(instancetype)init NS_UNAVAILABLE;

@property (nonatomic,weak) id<DLNAHomeManagerDelegate> delegate;

/// we will collect the action messages not received while renderer is presenting.
-(void)endPresentRenderer;

-(void)pickMissingActionMessages:(id<DLNAActionListener>)picker;

@end

@protocol DLNAHomeManagerDelegate  <NSObject>
@required
-(void)dlnaManagerNeedPresentRenderer:(DLNAHomeManager*)mng ;
-(void)dlnaManagerNeedDismissRenderer:(DLNAHomeManager*)mng ;

//sended when a resource was send to a new renderer.
-(void)newRendererConnected:(DLNAHomeManager*)mng;

@end

