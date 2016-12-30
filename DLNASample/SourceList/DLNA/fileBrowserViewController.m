//
//  fileBrowserViewController.m
//  Genie_Main
//
//  Created by liaogang on 16/7/21.
//  Copyright © 2016年 netgear. All rights reserved.
//

#import "fileBrowserViewController.h"
#import "CellDataA.h"
#import "ThreadJob.h"
#import "DlnaControlPoint.h"
#import "renderTableViewController.h"
#import "UIAlertViewBlock.h"
#import <PINRemoteImage/PINImageView+PINRemoteImage.h>
#import "constFunctions.h"
#import <LGPhotoBrowser/LGPhotoBrowser.h>
#import "photoPageViewController.h"
#import <LGPhotoBrowser/LGSpringAnimator.h>
#import "ThreadJob.h"

@interface fileBrowserViewController ()
<UITableViewDelegate,
UITableViewDataSource,
LGCollectionViewDataSource,
LGCollectionViewDelegate,
UINavigationControllerDelegate,
LGSpringAnimatorDelegate,
renderTableViewControllerDelegate
>
{
    NSUInteger selectedIndex;
    BOOL viewJustLoad;
    bool allphoto;
}
@property (nonatomic,weak) NSArray<CellDataA*>* cellsData;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activity;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet LGCollectionView *collectionView;
@property (weak,nonatomic) DlnaControlPoint *ctrlPoint;
@property (weak, nonatomic) IBOutlet UILabel *labelNoItem;
@end

@implementation fileBrowserViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
 
    self.ctrlPoint = [DlnaControlPoint shared];
    viewJustLoad = true;
    selectedIndex = -1;

    [self reloadData];
}

-(void)photoBrowserIndexChanged:(NSNotification*)n
{
    NSNumber *number = n.object;
    
    [self.collectionView scrolltoAndSelectIndex:number.unsignedIntegerValue];
    
    [self.collectionView setNeedsDisplay];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];

}

-(void)willMoveToParentViewController:(UIViewController *)parent
{
    // View is disappearing because it was popped from the stack
    //退回上级时,调用cdup,再刷新数据调用ls.
    if (parent == nil)
    {
        [_ctrlPoint cmd_cdup];
    }
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)reloadData
{
    
    dojobInBkgnd(^{
        [_ctrlPoint cmd_ls];
    }, ^{
        [self.activity stopAnimating];
        
        self.cellsData = _ctrlPoint.browsing;
        
        if (self.cellsData.count > 0)
        {
            allphoto = true;
            for (CellDataA* data in self.cellsData) {
                if ([data getType] == Photo) {
                }
                else{
                    allphoto = false;
                    break;
                }
            }
            
            
            
            if (allphoto) {
                [self.tableView removeFromSuperview];
                self.tableView = nil;
                
                self.collectionView.hidden = NO;
                [self.collectionView reloadData];
            }
            else{
                [self.collectionView removeFromSuperview];
                self.collectionView = nil;
                
                
                self.tableView.hidden = NO;
                [self.tableView reloadData];
            }
        }
        else
        {
            self.labelNoItem.hidden = FALSE;
        }
        
    });
   
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _cellsData.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger row = indexPath.row;
    
    CellDataA *data = self.cellsData[row];
    
    NSString *idn ;
    if (data.type == Folder) {
        
        NSString *title = [data getTitle].lowercaseString;
        
        if ([title rangeOfString:@"photo"].length > 0) {
            idn = @"folder-picture";
        }
        else if([title rangeOfString:@"video"].length > 0){
            idn = @"folder-video";
        }
        else if([title rangeOfString:@"music"].length > 0){
            idn = @"folder-music";
        }else{
            idn = @"folder";
        }
        
    }
    else if(data.type == Music)
    {
        idn = @"music";
    }
    else if(data.type == Normal ){
        idn = @"file";
    }
    else if( data.type == Video){
        idn = @"file";
    }
    else{
        assert(false);
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:idn  forIndexPath:indexPath];
    
    
    const int ImageTag = 1;
    const int TitleTag = 2;
    const int SubtitleTag = 3;
    const int MusicTimeTag = 4;
    
    
    UIImageView* imageView = [cell.contentView viewWithTag:ImageTag];
    NSAssert([imageView isKindOfClass:[UIImageView class]], @"cell imageView ?");
    UILabel *titleLabel = [cell.contentView viewWithTag:TitleTag];
    UILabel *subtitleLabel = [cell.contentView viewWithTag:SubtitleTag];
    UILabel *timeLabel = [cell.contentView viewWithTag:MusicTimeTag];
    
    
    titleLabel.text = data.title;
    
    if (data.type == Folder) {
        subtitleLabel.text = data.detail;
    }
    else{
        subtitleLabel.text = data.subTitle;
        [imageView pin_setImageFromURL:data.imageURL placeholderImage: data.placeHolder ];
    }
    
    if ( data.type == Music) {
        timeLabel.text = data.detail;
        subtitleLabel.text = data.subTitle;
    }
    
    
    return cell;
}

#pragma mark - UITableViewDelegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    int row = (int)indexPath.row;
    CellDataA *data = self.cellsData[row];
    
    selectedIndex = row;
    
    if ( [data getType ] == Folder )
    {
        [_ctrlPoint cmd_cd:row];
    }
    else
    {
        if ( _ctrlPoint.currentRenderer )
        {
            [self itemSelected:row];
        }
    }
    
}



-(void)itemSelected:(NSUInteger)index
{
    if ( [_ctrlPoint openIndex: index ] )
    {
        [_ctrlPoint performSelector:@selector(cmd_play) withObject:nil afterDelay:0.5];
    }
    else
    {
        [self showAlertViewNotSupport];
    }
    
}

#pragma mark - LGCollectionViewDataSource

-(NSUInteger)lg_numberOfItemsInCollectionView:(LGCollectionView *)collectionView
{
    return self.cellsData.count;
}

-(NSURL *)lg_urlForIndex:(NSUInteger)index inCollectionView:(LGCollectionView *)collectionView
{
    CellDataA *d = self.cellsData[index];
    return d.imageURL;
}

#pragma mark -LGCollectionViewDelegate

-(void)lg_collectionView:(LGCollectionView *)collectionView didClickedAtIndex:(NSUInteger)index
{
    selectedIndex = index;
    [self performSegueWithIdentifier:@"showPhotoPage" sender:self];
}

#pragma mark - navigation delegate

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    
    self.navigationController.delegate = self;
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    
    if (self.navigationController.delegate == self) {
        self.navigationController.delegate = nil;
    }
}


-(id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC
{
    if ( operation == UINavigationControllerOperationPush )
    {
        if (allphoto)
        {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(photoBrowserIndexChanged:) name:notifyPhotoBrowserViewController object:nil];
            
            return  [[LGSpringAnimator alloc]initWithOperation:operation from:(id<LGSpringAnimatorDelegate>)fromVC to:(id<LGSpringAnimatorDelegate>)toVC];
        }
        else{
            return nil;
        }
    }
    else
    {
        return nil;
    }
}

-(ImageAndFrame *)viewControllerAnimatorImageFrames
{
    return  getShowingImageViewFrom(self.collectionView);
}

#pragma mark -

-(void)showAlertViewNotSupport
{
    [[[UIAlertViewBlock alloc]initWithTitle:NSLocalizedString(@"Can not play the media", nil)  message:NSLocalizedString(@"The render do not support the resource type",nil) cancelButtonTitle:nil cancelledBlock:nil okButtonTitles: UIKitLocalizedString(@"OK") okBlock:nil] show];
}


#pragma mark - render delegate

-(void)rendererChanged:(NSUInteger)index
{
    if (index != -1)
    {
        [self itemSelected:index];
    }
    
}


#pragma mark - segue

-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ( [identifier rangeOfString:@"showRendererSelect"].length > 0 ) {
        // don't show the renderer selecter view controller when already have one.
        if ( _ctrlPoint.currentRenderer ) {
            return FALSE;
        }
    }
    
    return TRUE;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    bool title_setted = false;
    
    if ([segue.identifier rangeOfString:@"showRendererSelect"].length > 0) {
        UINavigationController *nav =segue.destinationViewController;
        renderTableViewController *rVC = nav.viewControllers.firstObject;
        rVC.delegate = self;

    }
    else if ([segue.identifier isEqualToString:@"showPhotoPage"]) {
        photoPageViewController *photoViewController = segue.destinationViewController;
        photoViewController.firstPageIndex = selectedIndex;
        photoViewController.cellsData = self.cellsData;
        title_setted = true;
    }
    
    
    if( title_setted == false )
    {
        UITableViewCell *cell = sender;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell ];
        UIViewController *vc = segue.destinationViewController;
        CellDataA *d = self.cellsData[indexPath.row];
        vc.title = d.title ;
    }
}

@end

