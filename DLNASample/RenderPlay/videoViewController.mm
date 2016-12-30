//
//  videoViewController.m
//  DLNASample
//
//  Created by liaogang on 16/12/6.
//  Copyright © 2016年 liaogang. All rights reserved.
//

#import "videoViewController.h"
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import "DLNAHomeManager.h"
#import "CellDataA.h"
#import "MediaPanel.h"

void * context_rate = &context_rate;
void * context_duration = &context_duration;

@interface videoViewController ()
<DLNAActionListener>
{
    bool lastCmdIsSetAVTransportURI;
    bool picked;
    dispatch_source_t	_timer;
}
@property (nonatomic,strong) AVPlayerViewController *avp;
@property (nonatomic,strong) CellDataA *currentURIMetaDataItem;
@end

@implementation videoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.avp = [[AVPlayerViewController alloc] init];
    [self.avp.view setFrame:self.view.bounds];
    
    
    [self.view addSubview:self.avp.view];
    
    
    
    self.avp.player = [[AVPlayer alloc]init];
    [self.avp.player addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionNew context:context_rate];
    
    self.avp.player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    
    NSNotificationCenter *d =[NSNotificationCenter defaultCenter];
    [d addObserver:self selector:@selector(DidPlayToEndTime:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
    
    // Update the UI 5 times per second
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(_timer, DISPATCH_TIME_NOW, NSEC_PER_SEC / 2, NSEC_PER_SEC / 3);
    
    dispatch_source_set_event_handler(_timer, ^{
        
        if ( self.avp.player.rate == 1.0)
        {
            [DlnaRender shared].mydirty.currentTime = CMTimeGetSeconds(self.avp.player.currentTime);
            [[DlnaRender shared] notifyDirty];
            
        }
    });
    
    // Start the timer
    dispatch_resume(_timer);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    if (picked == false) {
        [[DLNAHomeManager shared] pickMissingActionMessages:self];
        picked = true;
    }
    
}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[DlnaRender shared] addActionListener:self];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.avp.player pause];
    
    [[DlnaRender shared] removeActionListener:self];
}


-(void)actionComing:(DLNAActionType)type from:(MediaPanelN2H *)controller
{
    if ( self.view.hidden == FALSE )
    {
        switch (type) {
            case setAVTransportURI:
            {
                lastCmdIsSetAVTransportURI = true;
                if (controller.avTransportURL) {
                    self.currentURIMetaDataItem = [controller getURIMedaData];
                }
                else{
                    self.currentURIMetaDataItem = nil;
                }
            }
                break;
            case Play:
            {
                if (lastCmdIsSetAVTransportURI) {
                    
                    AVPlayerItem *item = [AVPlayerItem playerItemWithURL: [NSURL URLWithString: controller.avTransportURL]];
                    
                    [self.avp.player replaceCurrentItemWithPlayerItem:item];
                    
                    [item addObserver:self forKeyPath:@"duration" options:NSKeyValueObservingOptionNew context: context_duration];
                    
                    [self.avp.player play];
                    lastCmdIsSetAVTransportURI = false;
                }
                else{
                    [self.avp.player pause];
                }
                
            }
                break;
            case Pause:
            {
                [self.avp.player pause];
            }
                break;
            case Seek:
            {
                CMTime time = CMTimeMakeWithSeconds( controller.seekSecond * 60 , 60);
                [self.avp.player seekToTime: time];
            }
                break;
                
            default:
                break;
        }
        
        
        [self updateUI];
        
    }
    
}


-(void)updateUI
{

}

- (IBAction)actionDone:(id)sender {
    [[DLNAHomeManager shared].delegate dlnaManagerNeedDismissRenderer:[DLNAHomeManager shared]];
    
}

-(void)DidPlayToEndTime:(NSNotification*)n
{
    DlnaRender *r = [DlnaRender shared];
    r.mydirty.currentTime = 0;
    r.mydirty.duration = 0;
    r.mydirty.duration = 0;
    r.mydirty.playState = PlayState_stopped;
    [r notifyDirty];
    
    [self actionDone: nil];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if (context == context_rate)
    {
        DlnaRender *r = [DlnaRender shared];
        r.mydirty.playState = self.avp.player.rate == 0 ? PlayState_paused : PlayState_playing;
        [r notifyDirty];
    }
    else if( context == context_duration)
    {
        DlnaRender *r = [DlnaRender shared];
        NSTimeInterval time = CMTimeGetSeconds(self.avp.player.currentItem.duration);
        r.mydirty.duration = time;
        [r notifyDirty];
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
    
}

@end
