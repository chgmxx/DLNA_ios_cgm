//
//  LGPINRemoteImageDownloaderEx.h
//  ASPhotoBrowser
//
//  Created by liaogang on 16/8/29.
//  Copyright © 2016年 liaogang. All rights reserved.
//

#import <AsyncDisplayKit/ASImageProtocols.h>


///Copied from class ASPINRemoteImageDownloader , offer a tranformed image downloader
@interface LGPINRemoteImageDownloaderEx : NSObject <ASImageCacheProtocol, ASImageDownloaderProtocol>

///default image downloader for photo browser in lanscape mode
+ (instancetype )sharedDownloader;

///default image downloader for photo browser in collection mode
+ (instancetype )sharedTransformedDownloader;

-(void)setScaleSize:(CGSize)size;

-(void)clearMemory;

@end
