//
//  renderTableViewController.m
//  demo
//
//  Created by liaogang on 15/5/20.
//  Copyright (c) 2015年 com.cs. All rights reserved.
//

#import "renderTableViewController.h"
#import "DlnaControlPoint.h"
#import <PINRemoteImage/PINImageView+PINRemoteImage.h>
#import "Reachability.h"
#import "CellDataA.h"
#import "DlnaRender.h"
#import "constFunctions.h"
#import "UPnPCenter.h"


@interface UITableViewCellRender : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *renderImage;
@property (weak, nonatomic) IBOutlet UILabel *renderTitle;
@end

@implementation UITableViewCellRender
@end



@interface renderTableViewController ()
<ControlPointEventListener>
{
    NSUInteger currSelectedIndex;
    NSUInteger firstSelectedIndex;
}
@property (nonatomic,strong) DlnaControlPoint * ctrlPoint;
@property (nonatomic,strong) NSArray<MediaDevice*>* renderers;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *barItemDone;
@end


@implementation renderTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    self.ctrlPoint = [DlnaControlPoint shared];
    [self.ctrlPoint addListener: self];
    
    if (self.oneClick) {
        self.navigationItem.rightBarButtonItem = nil;
    }
    
    [self reloadData];
}

-(void)eventComing:(event_name)event_type from:(DlnaControlPoint *)ctrlPoint
{
    if (event_type == event_render_list_changed) {
        [self reloadData];
    }
    
}


-(void)reloadData
{
    self.renderers = _ctrlPoint.renderers;
    
    firstSelectedIndex = currSelectedIndex = [_renderers indexOfObject: _ctrlPoint.currentRenderer];
    
    [self.tableView reloadData];
    
    if (_renderers.count== 0)
    {
        
        NSString *message;
        if ([UPnPCenter shared].reachability.currentReachabilityStatus == NotReachable)
        {
            message = NSLocalizedString(@"Network not reachable", nil);
        }
        else{
            message = NSLocalizedString(@"No items", nil);
        }
        
        if (!self.tableView.backgroundView) {
            self.tableView.backgroundView = [[UIView alloc]initWithFrame: self.tableView.bounds];
        }
        
        showMessageInCentreOfView(self.tableView.backgroundView, message);
    }
    else{
        hideMessageInCentreOfView(self.tableView.backgroundView);
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}





#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _renderers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger row = indexPath.row;
    
    
    UITableViewCellRender *cell = [tableView dequeueReusableCellWithIdentifier: @"renderTableCell" forIndexPath:indexPath];
    
    MediaDevice *device = _renderers[row];
    
    
    if( row == currSelectedIndex )
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else
        cell.accessoryType = UITableViewCellAccessoryNone;
    
    cell.renderTitle.text = [device GetFriendlyName];
    
    [cell.renderImage pin_setImageFromURL:[device GetIconUrl] placeholderImage:[UIImage imageNamed:@"defaultrender"]];
    
    return cell;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    currSelectedIndex = indexPath.row;
    
    
    if (self.oneClick)
    {
        [_ctrlPoint chooseRenderer: currSelectedIndex];
        
        if (self.delegate) {
            [self.delegate rendererChanged: currSelectedIndex ];
        }
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
    else
    {
        bool isDirty = currSelectedIndex != firstSelectedIndex;
        self.barItemDone.enabled = isDirty? TRUE: FALSE;
    }
    
    [tableView reloadRowsAtIndexPaths: [tableView indexPathsForVisibleRows] withRowAnimation: UITableViewRowAnimationAutomatic];
}

- (IBAction)actionDone:(id)sender {
    [_ctrlPoint chooseRenderer: currSelectedIndex];
    
    if (self.delegate) {
        [self.delegate rendererChanged: currSelectedIndex ];
    }
    
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)actionCancel:(id)sender {
    
    if (self.delegate) {
        [self.delegate rendererChanged: -1 ];
    }
    
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

@end

