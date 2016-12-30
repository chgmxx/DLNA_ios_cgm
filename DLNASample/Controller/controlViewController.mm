//
//  playerViewController.m
//  demo
//
//  Created by liaogang on 15/5/20.
//  Copyright (c) 2015年 com.cs. All rights reserved.
//

#import "controlViewController.h"
#import "DlnaControlPoint.h"
#import "UISlider+hideThumbWhenDisable.h"
#import "renderTableViewController.h"
#import <PINRemoteImage/PINImageView+PINRemoteImage.h>
#import "CellDataA.h"
#import "MediaPanel.h"


@interface controlViewController ()
<ControlPointEventListener,
UITableViewDelegate,
UITableViewDataSource,
renderTableViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImage;
@property (weak, nonatomic) IBOutlet UILabel *leftTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *rightTimeLabel;
@property (weak, nonatomic) IBOutlet UISlider *posSlider;
@property (weak, nonatomic) IBOutlet UISlider *volumnSlider;

@property (weak, nonatomic) IBOutlet UIButton *voiceIsOn;
@property (weak, nonatomic) IBOutlet UIButton *voiceIsOff;

@property (weak, nonatomic) IBOutlet UIButton *prevBtn;
@property (weak, nonatomic) IBOutlet UIButton *playBtn;
@property (weak, nonatomic) IBOutlet UIButton *pauseBtn;
@property (weak, nonatomic) IBOutlet UIButton *nextBtn;

@property (nonatomic) bool isSeeking;

@property (weak, nonatomic) IBOutlet UILabel *mediaTitle;

@property (weak, nonatomic) IBOutlet UILabel *subTitle;

@property (nonatomic) PlayState2 lastState;

/**
 *  The entire volume control container, including the label.
 */
@property(strong, nonatomic) IBOutlet UIView *volumeControls;

/* A timer to trigger removal of the volume control. */
@property(weak, nonatomic) NSTimer *fadeVolumeControlTimer;

@property (nonatomic) unsigned int volume;

/**
 *  The label in the volume control container.
 */
@property(weak, nonatomic) IBOutlet UILabel *volumeControlLabel;

@property (nonatomic) DlnaControlPoint *ctrlPoint;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@end

@implementation controlViewController

-(void)dealloc
{
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.ctrlPoint = [DlnaControlPoint shared];
    [self.ctrlPoint addListener: self];
    
    [self updateUIControls:_ctrlPoint.render];

    CALayer *layer =self.volumeControls.layer;
    layer.cornerRadius = 7.0;
    layer.shadowOpacity = 0.5;
    layer.shadowRadius = 7;
    layer.shadowColor = [UIColor blackColor].CGColor;
    layer.shadowOffset = CGSizeMake(0, 2.5);
}

-(void)eventComing:(event_name)event_type from:(DlnaControlPoint *)ctrlPoint
{
    if( event_type == event_state_variables_changed)
    {
        [self updateUIControls: ctrlPoint.render];
    }
    else if( event_type == event_rendering_control_response)
    {
        [self updateTrackPosition:ctrlPoint.render];
    }
    else if( event_type == event_render_list_changed || event_type == event_user_choosed_renderer )
    {
        [self.tableView reloadData];
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Update

-(void)updateTrackPosition:(MediaPanel*)mediaPanel
{
    if (! self.isSeeking  )
    {
        self.posSlider.maximumValue = mediaPanel.duration;
        self.posSlider.value = mediaPanel.currentTime;
        
        self.leftTimeLabel.text = [NSString stringWithUTF8String: dlna_second_to_stirng( mediaPanel.currentTime)];
        
        self.rightTimeLabel.text = [NSString stringWithUTF8String: dlna_second_to_stirng( mediaPanel.duration)];
        
    }
    
}

-(void)updateUIControls:(MediaPanel*)mediaPanel
{
    NSAssert([NSThread currentThread].isMainThread, nil);
    
    switch (mediaPanel.playState)
    {
        case PlayState_unknown:
        case PlayState_stopped:
        {
            self.mediaTitle.text = @"";
            self.subTitle.text = @"";
            self.backgroundImage.image = nil;
            
            self.playBtn.hidden = NO;
            self.pauseBtn.hidden = YES;
            [self.posSlider setSliderEnabled:FALSE];
            self.posSlider.value = 0.;
            
            self.rightTimeLabel.text = self.leftTimeLabel.text  = @"00:00:00";
            self.rightTimeLabel.enabled = self.leftTimeLabel.enabled = false;
            
            
            [self.posSlider setSliderEnabled:false];
            self.voiceIsOn.enabled = false;
            
            if (mediaPanel.playState == PlayState_unknown) {
                self.playBtn.enabled = false;
            }
            else{
                self.playBtn.enabled = true;
            }
            
            
            self.pauseBtn.enabled = false;
            self.prevBtn.enabled = false;
            self.nextBtn.enabled = false;
            
            break;
        }
        case PlayState_playing:
        {
            if ( self.lastState != PlayState_playing )
            {
                MediaDevice *renderer = _ctrlPoint.currentRenderer ;
                
                if ( renderer )
                {
                    self.subTitle.text = [NSString stringWithFormat:@"Playing On %@",  [renderer GetFriendlyName]];
                    
                    CellDataA *data = [_ctrlPoint getOpenedMedia];
                    NSString *title = [data getTitle];
                    self.mediaTitle.text = title;
                    [self.backgroundImage pin_setImageFromURL: data.imageURL];
                    
                    self.volumeControlLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ Volume", nil),  [renderer GetFriendlyName]] ;
                }
                
                self.nextBtn.enabled = YES;
                self.prevBtn.enabled = YES;
                self.pauseBtn.enabled = true;
                self.playBtn.enabled = true;
                self.voiceIsOn.enabled = YES;
                self.volumnSlider.enabled = YES;
                self.rightTimeLabel.enabled = self.leftTimeLabel.enabled = true;
                self.posSlider.enabled = YES;
                
                UIImage *thumb = [UIImage imageNamed:@"thumb"];
                [_posSlider setThumbImage:thumb forState:UIControlStateNormal];
                [_posSlider setThumbImage:thumb forState:UIControlStateHighlighted];
    
                
                self.playBtn.hidden = YES;
                self.pauseBtn.hidden = FALSE;
            }
            break;
        }
        case PlayState_paused:
        {
            self.posSlider.enabled = YES;
            UIImage *thumb = [UIImage imageNamed:@"thumb"];
            [_posSlider setThumbImage:thumb forState:UIControlStateNormal];
            [_posSlider setThumbImage:thumb forState:UIControlStateHighlighted];
            
            
            self.playBtn.hidden = NO;
            self.pauseBtn.hidden = YES;
            break;
        }
        default:
            break;
    }
    
    if ( mediaPanel.mute) {
        self.voiceIsOff.hidden = false;
        self.voiceIsOn.hidden = true;
    }
    else
    {
        self.voiceIsOff.hidden = true;
        self.voiceIsOn.hidden = false;
    }
    
    
//    if (!self.volumnSlider.isHighlighted)
//        self.volumnSlider.value = mediaPanel.volume;
    
    if ( self.volume != mediaPanel.volume ) {
        self.volume = mediaPanel.volume;
        self.volumnSlider.value = self.volume;
        [self actionShowVolume:nil];
    }
    
   
    
    self.lastState = mediaPanel.playState;

}



-(bool)openNext
{
    NSInteger openedIndex =  [_ctrlPoint getOpenedMediaIndex];
    
    NSUInteger count = _ctrlPoint.browsing.count;
    
    NSInteger next = openedIndex + 1;
    
    if ( next == count ) {
        next = 0;
    }
    
    return [_ctrlPoint openIndex: next];
}


-(bool)openPrev
{
    NSInteger openedIndex =  [_ctrlPoint getOpenedMediaIndex];
    
    NSUInteger count = _ctrlPoint.browsing.count;
    
    NSInteger prev = openedIndex - 1;
    
    if ( prev == -1 ) {
        prev = count - 1;
    }
    
    return [_ctrlPoint openIndex: prev];
}

-(void)setSeekingFalse
{
    self.isSeeking = false;
}

-(void)resumePlay
{
    [_ctrlPoint cmd_play];
}

#pragma mark - Control actions

- (IBAction)positionReleased:(UISlider *)sender {
    NSLog(@"positionDragExit");
    [_ctrlPoint cmd_seek: sender.value ];
    [self performSelector:@selector(setSeekingFalse) withObject:nil afterDelay:1.0];
}

- (IBAction)posSliding:(UISlider *)sender
{
    NSLog(@"positionSliderChanged");
    
    self.leftTimeLabel.text = [NSString stringWithUTF8String:dlna_second_to_stirng(sender.value) ];
   
    self.isSeeking = true;
}


- (IBAction)volumnDragExit:(UISlider *)sender {
    [_ctrlPoint cmd_setVolumn:sender.value];
}

- (IBAction)actionVoiceOff:(UIButton*)sender {
    [_ctrlPoint cmd_mute];
}

- (IBAction)actionVoiceOn:(UIButton*)sender {
    [_ctrlPoint cmd_unmute];
}

- (IBAction)actionPrev:(id)sender {
    [self openPrev];
}

- (IBAction)actionStop:(id)sender {
    [_ctrlPoint cmd_stop];
    self.mediaTitle.text = @"";
}

-(void)sendPlayCmd
{
    [_ctrlPoint cmd_play];
}

- (IBAction)actionPlay:(id)sender {
    if (_ctrlPoint.render.playState == PlayState_paused)
    {
        [self resumePlay];
    }
    else
    {
        [_ctrlPoint cmd_play];
    }
}

- (IBAction)actionPause:(id)sender {
    [_ctrlPoint cmd_pause];
}

- (IBAction)actionNext:(id)sender {
    [self openNext];
}


-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self showVolume];
}

-(void)showVolume
{
     if (self.volumeControls.hidden) {
        self.volumeControls.hidden = NO;
        [self.volumeControls setAlpha:0];
        
        self.volumnSlider.value = self.volume;
        
        [UIView animateWithDuration:0.5
                         animations:^{
                             self.volumeControls.alpha = 1.0;
                         }
                         completion:^(BOOL finished){
                             NSLog(@"Volume slider hidden done!");
                         }];
        
    }
    // Do this so if a user taps the screen or plays with the volume slider, it resets the timer
    // for fading the volume controls
    if (self.fadeVolumeControlTimer != nil) {
        [self.fadeVolumeControlTimer invalidate];
    }
    self.fadeVolumeControlTimer = [NSTimer scheduledTimerWithTimeInterval:3.0
                                                                   target:self
                                                                 selector:@selector(fadeVolumeSlider:)
                                                                 userInfo:nil
                                                                  repeats:NO];
    
 
}

- (IBAction)actionShowVolume:(id)sender {
    [self showVolume];
    
}

- (void)fadeVolumeSlider:(NSTimer *)timer {
    [self.volumeControls setAlpha:1.0];
    
    [UIView animateWithDuration:0.5
                     animations:^{
                         self.volumeControls.alpha = 0.0;
                     }
                     completion:^(BOOL finished){
                         self.volumeControls.hidden = YES;
                     }];
}


#pragma mark - UITableviewDataSource

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MediaDevice *currentRenderer = self.ctrlPoint.currentRenderer;
    
    if ( currentRenderer)
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell2"];
        UILabel *textLabel = [cell.contentView viewWithTag:1];
        textLabel.text = [currentRenderer GetFriendlyName];
        
        UIImageView *imageView = [cell.contentView viewWithTag:2];
        [imageView pin_setImageFromURL:[currentRenderer GetIconUrl] placeholderImage:[UIImage imageNamed:@"defaultrender"]];
        
        return cell;
    }
    else
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell1"];
        return cell;
    }
    
}

- (void)tableView:(UITableView *)tableView
  willDisplayCell:(UITableViewCell *)cell
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [cell setBackgroundColor:[UIColor clearColor]];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark - render delegate

-(void)rendererChanged:(NSUInteger)index
{
    if (index != -1)
    {
        [self.tableView reloadData];
    }
    
}

#pragma mark - Navigation segue

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier rangeOfString:@"showRendererSelect"].length > 0) {
        UINavigationController *nav =segue.destinationViewController;
        renderTableViewController *rVC = nav.viewControllers.firstObject;
        rVC.oneClick = TRUE;
    }
   

}

@end
