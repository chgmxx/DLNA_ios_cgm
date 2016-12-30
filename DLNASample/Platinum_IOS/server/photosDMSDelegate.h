//
//  photosDMSDelegate.h
//  demo
//
//  Created by geine on 6/15/15.
//  Copyright (c) 2015 com.cs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PltMediaServerObjectMy.h"
#import <AssetsLibrary/AssetsLibrary.h>


@interface photosDMSDelegate : NSObject <PLT_MediaServerDelegateObject>

+ (ALAssetsLibrary *)defaultAssetsLibrary;

/// 照片专辑数
/// 视频数
/// @param type , 0 -> videos , 1 -> photo groups
-(int)groupCount:(int)type;

@end

const char* getRootIdPhoto();
int getRootIdPhotoLen();

const char* getRootIdVideo();
int getRootIdVideoLen();
