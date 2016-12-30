//
//  photoViewController.m
//  demo
//
//  Created by liaogang on 15/6/26.
//  Copyright (c) 2015年 com.cs. All rights reserved.
//

#import "photoViewController.h"
#import <PINRemoteImage/PINImageView+PINRemoteImage.h>
#import "DlnaRender.h"
#import "PlatinumIOSConst.h"
#import "MediaPanel.h"

@interface photoViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *photo;
@end

@implementation photoViewController

-(void)stop
{
    [DlnaRender shared].mydirty.playState = PlayState_stopped;
    [[DlnaRender shared] notifyDirty];
}

-(void)showPhoto:(NSURL*)url
{
    NSLog(@"show photo: %@",url);
    
    [self.photo pin_setImageFromURL:url placeholderImage:nil];
//    [self.photo setImageWithURL:url placeholderImage:nil options: SDWebImageDelayPlaceholder ];
}

@end
