//
//  sourceDeviceController.mm
//  demo
//
//  Created by liaogang on 15/9/17.
//  Copyright (c) 2015年 com.cs. All rights reserved.
//

#import "sourceDeviceController.h"
#import <PINRemoteImage/PINImageView+PINRemoteImage.h>
#import "Reachability.h"
#import "DlnaControlPoint.h"
#import "constDefines.h"
#import "UPnPCenter.h"
#import "constFunctions.h"

@interface UITableViewCellSource : UITableViewCell
@property (nonatomic,strong) IBOutlet UIImageView *cellImage;
@property (nonatomic,strong) IBOutlet UILabel *cellText;
@property (nonatomic,strong) IBOutlet UILabel *cellDetailText;
@end


@interface sourceDeviceTableViewController ()
<ControlPointEventListener>
@property (nonatomic,weak) DlnaControlPoint *ctrlPoint;
@property (nonatomic,strong) NSArray<MediaDevice*> *servers;

@end

@implementation sourceDeviceTableViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
 
    [self setup];
}


-(void)setup
{
    self.ctrlPoint = [DlnaControlPoint shared];
    [_ctrlPoint addListener: self];
    
   
    [self reloadData];
}

-(void)eventComing:(enum event_name)event_type from:(DlnaControlPoint *)ctrlPoint
{
    if (event_type == event_media_server_list_changed)
    {        
        [self reloadData];
    }
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [super viewWillAppear:animated];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    //view disapper because a new viewcontroller is pushed in stack?
    if (self.navigationController.viewControllers.count > 1) {
        [self.navigationController setNavigationBarHidden:NO animated:YES];
    }

}

-(void)reloadData
{
    NSAssert( [NSThread currentThread].isMainThread, @"main thread.");
    
    NSLog(@"source devices : refresh");
    self.servers = [DlnaControlPoint shared].servers;
    
    [self.tableView reloadData];
    
    
    if (_servers.count == 0)
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


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.servers.count;
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int row = (int)indexPath.row;
    
    NSString *idn = @"deviceListCell";
    
    UITableViewCellSource *cell = [tableView dequeueReusableCellWithIdentifier:idn forIndexPath:indexPath];
    
    MediaDevice *device = _servers[row];
    
    NSAssert([UIImage imageNamed:@"defaultserver"] , nil);
    
    NSURL *iconURL = [device GetIconUrl];
    
    [cell.cellImage pin_setImageFromURL:iconURL placeholderImage:[UIImage imageNamed:@"defaultserver"]];
    
    cell.cellText.text = [device GetFriendlyName];
    
    cell.cellDetailText.text = [device GetModelDescription];
    
    return cell;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UITableViewCellSource *cell = [tableView dequeueReusableCellWithIdentifier:@"headerCell"];
 
    cell.textLabel.text = @"Devices";
    
    cell.backgroundColor = [UIColor clearColor];
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 66;
}

#pragma mark - didSelect AtIndexPath
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    int row = (int)indexPath.row;
    
    [_ctrlPoint chooseServer: row];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *viewController = segue.destinationViewController;
    
    UITableViewCell *cell = sender;
    
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    
    int row = (int)indexPath.row;
    
    MediaDevice *device = _servers[row];
    
    viewController.title = [device GetFriendlyName];
    
}

@end

@implementation UITableViewCellSource
@end

