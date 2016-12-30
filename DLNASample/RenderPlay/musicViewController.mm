//
//  musicViewController.m
//  demo
//
//  Created by liaogang on 15/6/26.
//  Copyright (c) 2015年 com.cs. All rights reserved.
//

#import "musicViewController.h"
#import "DlnaRender.h"
#import "PlayerEngine.h"
#import "PlayerMessage.h"
#import <PINRemoteImage/PINRemoteImage.h>
#import <PINRemoteImage/PINImageView+PINRemoteImage.h>
#import <MediaPlayer/MediaPlayer.h>
#import "CDRotationImageView.h"
#import "DLNAHomeManager.h"
#import "CellDataA.h"
#import "MediaPanel.h"

void valueToMinSec(double d, int *m , int *s);




@interface musicViewController ()
<DLNAActionListener>
{
    bool picked;
}

@property (weak, nonatomic) IBOutlet UILabel *labelTimeL;
@property (weak, nonatomic) IBOutlet UILabel *labelTimeR;

@property (weak, nonatomic) IBOutlet UISlider *posSlider;

@property (nonatomic,strong) CellDataA *currentURIMetaDataItem;

@property (nonatomic) bool isSeeking;

@property (nonatomic) int count;

@property (weak, nonatomic) IBOutlet CDRotationImageView *rotationAlbumImageView;

@property (strong, nonatomic) UIBarButtonItem *barItemPlay,*barItemPause;

@end

@implementation musicViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    addObserverForEvent(self , @selector(trackStarted:), EventID_track_started);
    addObserverForEvent(self , @selector(trackStopped), EventID_track_stopped);
    addObserverForEvent(self , @selector(playerStateChanged), EventID_track_state_changed);
    addObserverForEvent(self, @selector(updateProgressInfo:), EventID_track_progress_changed);
    
    UIImage *thumb = [UIImage imageNamed:@"thumb"];
    [_posSlider setThumbImage:thumb forState:UIControlStateNormal];
    [_posSlider setThumbImage:thumb forState:UIControlStateHighlighted];
    
    
    self.barItemPlay = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(actionPlaypause:)];
    self.barItemPlay.tintColor = [UIColor whiteColor];
    
    self.barItemPause = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause target:self action:@selector(actionPlaypause:)];
    self.barItemPause.tintColor = [UIColor whiteColor];
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
    [self stop];
    [[DlnaRender shared] removeActionListener:self];
}

-(void)actionComing:(DLNAActionType)type from:(MediaPanelN2H *)controller
{
    if ( self.view.hidden == FALSE )
    {
        switch (type) {
            case setAVTransportURI:
            {
                if (controller.avTransportURL) {
                    self.currentURIMetaDataItem = [controller getURIMedaData];
                    [self fillUI];
                    [[PlayerEngine shared] playURL:[NSURL URLWithString: controller.avTransportURL] ];
                }
                else{
                    self.currentURIMetaDataItem = nil;
                }
            }
                break;
            case Play:
            {
                [self play];
            }
                break;
            case Pause:
            {
                [self playPause];
            }
                break;
            case Stop:
            {
                [self stop];
                break;
            }
            case Seek:
            {
                [self seek: controller.seekSecond];
            }
                break;
                
            default:
                break;
        }
        
        
        [self updateUI];
        
    }
    
}

-(void)trackStopped
{
    ProgressInfo *info = [[ ProgressInfo alloc]init];
    info.total = 0.;
    info.current = 0.;
    [self _updateProgressInfo:info];
    [self updateUI];
    
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = nil;

    return;
}

-(void)playerStateChanged
{
    /// map from PlayState to PlayState2
    int map[] = {PlayState_stopped,PlayState_playing,PlayState_paused,PlayState_playing};
    
    PlayState playstate = [[PlayerEngine shared] getPlayState];

    [DlnaRender shared].mydirty.playState =(enum PlayState2) map[ (int)playstate];
    
    [[DlnaRender shared] notifyDirty];

    [self updateUI];
    
    if (playstate == playstate_playing)
        [self.rotationAlbumImageView startRotation];
    else
        [self.rotationAlbumImageView endRotation];
}

-(void)trackStarted:(NSNotification*)n
{
    ProgressInfo *info = n.object;
    NSAssert([info isKindOfClass:[ProgressInfo class]], nil);
    [self.posSlider setMaximumValue: info.total];
    [self.posSlider setValue: 0];
    
    
    [DlnaRender shared].mydirty.currentTime =  info.current  ;
    
    [DlnaRender shared].mydirty.duration =  info.total;
    
    [[DlnaRender shared] notifyDirty];
    
    [self updateUI];
}


-(void)_updateProgressInfo:(ProgressInfo *)info
{
    NSAssert([info isKindOfClass:[ProgressInfo class]], nil);
    
    if (info.total > 0)
    {
        [self.posSlider setMaximumValue: info.total];
        [self.posSlider setValue: info.current];
    }
    else
    {
        [self.posSlider setMaximumValue: 0];
        [self.posSlider setValue: 0];
    }
    
    int min , sec;
    
    valueToMinSec(info.current, &min, &sec);
    self.labelTimeL.text = [NSString stringWithFormat:@"%02d:%02d",min,sec];
    
    valueToMinSec(info.total, &min, &sec);
    self.labelTimeR.text = [NSString stringWithFormat:@"%02d:%02d",min,sec];
    
    
    [DlnaRender shared].mydirty.currentTime = info.current ;
    
    [DlnaRender shared].mydirty.duration =  info.total ;
    
    [[DlnaRender shared] notifyDirty];
}

-(void)updateProgressInfo:(NSNotification*)n
{
    if ( ! ( self.isSeeking  || self.posSlider.highlighted ) )
    {
        ProgressInfo *info = n.object;
        
        [self _updateProgressInfo:info];
    }
}



-(void)updateUI
{
    self.title = [self.currentURIMetaDataItem getTitle];
    
    
    if ([PlayerEngine shared].isPlaying)
    {
        self.navigationItem.leftBarButtonItem = _barItemPause;
    }
    else
    {
        self.navigationItem.leftBarButtonItem = _barItemPlay;
    }
    
    
    if ( [PlayerEngine shared].isStopped )
    {
        [self.posSlider setThumbImage:[UIImage imageNamed:@"clear_thumb"] forState:UIControlStateNormal];
    }
    else
    {
         UIImage *thumb = [UIImage imageNamed:@"thumb"];
        [_posSlider setThumbImage:thumb forState:UIControlStateNormal];
        [_posSlider setThumbImage:thumb forState:UIControlStateHighlighted];
    }
    
    
}

-(void)fillUI
{
    [self.rotationAlbumImageView pin_setImageFromURL:[self.currentURIMetaDataItem getImageURL]];
}


-(void)stop
{
    [[PlayerEngine shared]stop];
}

-(void)playPause
{
    [[PlayerEngine shared] playPause];
}

-(void)play{
    
    if([[PlayerEngine shared] isPlaying])
    {
        
    }
    else{
        [[PlayerEngine shared] playPause];
    }
    
}

-(void)pause{
    
    if([[PlayerEngine shared] isPlaying])
    {
        [[PlayerEngine shared] playPause];
    }
    
}

- (IBAction)actionPlaypause:(id)sender {
    [self playPause];
}

-(void)setSeekingFalse
{
    self.isSeeking = false;
}

- (IBAction)posSliding:(UISlider *)sender {
    float totalSecond = sender.value;
    
    int min = totalSecond / 60;
    
    int sec = totalSecond - min * 60;
    
    self.labelTimeL.text = [NSString stringWithFormat:@"%02d:%02d",min,sec];
}

- (IBAction)posEndChange:(UISlider*)sender {
    
    [self seek:sender.value];
    self.isSeeking = true;
    [self performSelector:@selector(setSeekingFalse) withObject:nil afterDelay:1.0f];
}

-(void)seek:(float)sec
{
    [[PlayerEngine shared] seekToTime: sec ];
}


- (IBAction)actionDone:(id)sender
{
    [[DLNAHomeManager shared].delegate dlnaManagerNeedDismissRenderer:[DLNAHomeManager shared]];
}

@end

void valueToMinSec(double d, int *m , int *s)
{
    *m = d / 60;
    *s = (int)d % 60;
}






