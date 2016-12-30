//
//  tabbarRendererController.m
//  DLNASample
//
//  Created by liaogang on 16/11/25.
//  Copyright © 2016年 liaogang. All rights reserved.
//

#import "tabbarRendererController.h"
#import "photoViewController.h"
#import "musicViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import "DlnaControlPoint.h"
#import "DlnaRender.h"
#import "DLNAHomeManager.h"
#import "MediaPanel.h"

@interface tabbarRendererController ()
<DLNAActionListener>

@property (nonatomic,strong) MPVolumeView* volumeView;

/// 0.0~1.0
@property (nonatomic) float volume;
@end


@implementation tabbarRendererController
-(void)viewDidLoad
{
    [super viewDidLoad];
    
    [[DLNAHomeManager shared] pickMissingActionMessages:self];
    
    [[DlnaRender shared] addActionListener:self];
    
    // set the render's volume by current system volume
    [DlnaRender shared].mydirty.volume = [[AVAudioSession sharedInstance] outputVolume] * 100 ;
    
    // Get notice when volume change.
    /// do not remove this line. @see http://stackoverflow.com/questions/3651252/how-to-get-audio-volume-level-and-volume-changed-notifications-on-ios#
    self.volumeView= [[MPVolumeView alloc]init];
    
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(volumeChanged:)
     name:@"AVSystemController_SystemVolumeDidChangeNotification"
     object:nil];
    
}



-(void)actionComing:(DLNAActionType)type from:(MediaPanelN2H*)controller
{
    const char *table[] =
    {
        "setAVTransportURI",
        "Play",
        "Pause",
        "Stop",
        "Seek",
        "Next",
        "Previous",
        "setPlayMode",
        "setVolume",
        "Mute",
    };
    
    NSLog(@"dlna action: %s", table[type]);
    
    
    
    if (type == setAVTransportURI)
    {
        enum{
            photo_tab_index,
            music_tab_index,
            video_tab_index,
        };
        
        NSUInteger index = 0;
        if(controller.mediaType ==DlnaUrlType_photo)
        {
            index = photo_tab_index;
        }
        else if(controller.mediaType ==DlnaUrlType_music)
        {
            index = music_tab_index;
        }
        else if (controller.mediaType == DlnaUrlType_video)
        {
            index = video_tab_index;
        }
        
        [self changedSelectedIndex:index];
    }
    else if (type == Mute)
    {
        [self setPlayerVolume:self.volume mute: controller.mute ];
        
        [DlnaRender shared].mydirty.mute = controller.mute;
        [[DlnaRender shared] notifyDirty];
    }
    else if (type == setVolume)
    {
        self.volume = controller.volume;
        
        if( ![DlnaRender shared].mydirty.mute )
            [self setPlayerVolume: controller.volume/100.0 mute:false];
        
        
        [DlnaRender shared].mydirty.volume = controller.volume;
        [[DlnaRender shared] notifyDirty];
    }

}

-(void)changedSelectedIndex:(NSUInteger)index
{
    UIViewController *vc = self.viewControllers[index];
    self.title = vc.tabBarItem.title;
    
    self.selectedIndex = index;
}


#pragma mark - system volume change

-(void)volumeChanged:(NSNotification *)notification
{
    // from 0.0 to 1.0
    float volume = [[[notification userInfo] objectForKey:@"AVSystemController_AudioVolumeNotificationParameter"] floatValue];
    
    if (![DlnaRender shared].controller.mute )
    {
        self.volume = volume ;
        [DlnaRender shared].mydirty.volume = (int)(volume * 100);
        [[DlnaRender shared] notifyDirty];
    }
    
}


/// 0.0~1.0
-(void)setPlayerVolume:(float)volume mute:(bool)mute
{
    /**
     This is a private API.
     @see http://stackoverflow.com/questions/19218729/ios-7-mpmusicplayercontroller-volume-deprecated-how-to-change-device-volume-no
     */
    //find the volumeSlider
    UISlider* volumeViewSlider = nil;
    for (UIView *view in [self.volumeView subviews]){
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            volumeViewSlider = (UISlider*)view;
            break;
        }
    }
    
    if (mute) {
        //        self.volume = [[AVAudioSession sharedInstance] outputVolume] ;
        [volumeViewSlider setValue:0.0 animated:YES];
    }
    else
    {
        [volumeViewSlider setValue:volume animated:YES];
    }
    
    
    [volumeViewSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
}

@end
