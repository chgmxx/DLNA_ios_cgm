//
//  CellDataA.h
//  Genie_Main
//
//  Created by liaogang on 16/7/21.
//  Copyright © 2016年 netgear. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "constDefines.h"


///A DLNA MediaItem oc version.
@interface CellDataA : NSObject

-(NSString* _Nonnull)getObjectID;

@property (nonatomic,getter=getType) enum MediaType type;

@property (nonatomic,strong,getter=getTitle) NSString *_Nullable title;

@property (nonatomic,strong,getter=getDetail) NSString *_Nullable detail;

@property (nonatomic,strong,getter=getImageURL) NSURL *_Nullable imageURL;

@property (nonatomic,strong,getter=getArtist) NSString *_Nullable artist;

@property (nonatomic,strong,getter=getAlbum) NSString *_Nullable album;

@property (nonatomic,strong,getter=getPlaceHolder) UIImage *_Nullable placeHolder;

@property (nonatomic,strong) NSString * _Nullable subTitle;

@end



@interface MediaDevice : NSObject

-(NSURL* _Nullable)GetIconUrl;

-(NSString* _Nullable)GetModelDescription;

-(NSString* _Nullable)GetFriendlyName;

-(NSString* _Nullable)GetUUID;

// whether device uuid is equal
-(BOOL)isEqual:(MediaDevice* _Nonnull)object;

@end
