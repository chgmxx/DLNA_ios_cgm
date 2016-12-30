//
//  ASNetworkImageCellNode.h
//  SDWebImage
//
//  Created by liaogang on 15/12/24.
//  Copyright © 2015年 liaogang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import <LGPhotoBrowser/LGPhotoBrowserConst.h>

@class ASCellNode;

/// CellNode with Image
@interface LGNetworkImageCellNode :ASCellNode

-(instancetype)initWithURL:(NSURL*)url contentMode:(UIViewContentMode)mode placeHodler:(UIImage*)placeHolder;

-(void)startDownload;

#if AS_SHOW_NUMBER
-(void)setTheText:(NSString*)s;
#endif

-(bool)imageLoaded;

-(UIImage*)getImage;

@end
