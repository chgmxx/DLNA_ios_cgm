//
//  ASNetworkImageScrollCellNode.h
//  SDWebImage
//
//  Created by liaogang on 15/12/25.
//  Copyright © 2015年 liaogang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AsyncDisplayKit/AsyncDisplayKit.h>


extern NSString *kLGPhotoBrowserSingleTapped;

/// Cell node ==> Scroll ==> Image
@interface LGNetworkImageScrollCellNode : ASCellNode

-(instancetype)initWithURL:(NSURL* )url placeHodler:(UIImage* )placeHolder;

-(void)startDownload;

-(UIImage*)getImage;

@end

