//
//  photoPageViewController.m
//  DLNASample
//
//  Created by liaogang on 16/11/17.
//  Copyright © 2016年 liaogang. All rights reserved.
//

#import "photoPageViewController.h"
#import <LGPhotoBrowser/LGPhotoBrowserView.h>
#import <LGPhotoBrowser/LGSpringAnimator.h>

NSString *notifyPhotoBrowserViewController = @"photoBrowserViewControllerIndexChanged";

@interface photoPageViewController ()
<LGPhotoBrowserViewDataSource,
LGPhotoBrowserViewDelegate,
UINavigationControllerDelegate,
LGSpringAnimatorDelegate>
@end

@implementation photoPageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    

    
    NSAssert(self.cellsData.count > self.firstPageIndex, @"");
    
    self.title = [NSString stringWithFormat:@"%lu/%lu",self.firstPageIndex+1, (unsigned long)self.cellsData.count];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


#pragma mark - LGPhotoBrowserViewDataSource
-(NSUInteger)lg_firstIndexOfPhotoBrowserView:(LGPhotoBrowserView *)photoBrowserView
{
    return self.firstPageIndex;
}

-(NSUInteger)lg_numberOfItemsInPhotoBrowserView:(LGPhotoBrowserView *)photoBrowserView
{
    return self.cellsData.count;
}

-(NSURL *)lg_urlForIndex:(NSUInteger)index inPhotoBrowserView:(LGPhotoBrowserView *)photoBrowserView
{
    CellDataA *d = self.cellsData[index];
    return d.imageURL;
}

#pragma mark -LGPhotoBrowserViewDelegate
-(void)lg_indexChanged:(NSUInteger)index inPhotoBrowserView:(LGPhotoBrowserView *)photoBrowserView
{
    self.title = [NSString stringWithFormat:@"%lu/%lu",[photoBrowserView getPageIndex]+1, (unsigned long)self.cellsData.count];
    
    NSNumber *number = [NSNumber numberWithUnsignedInteger: index];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"photoBrowserViewControllerIndexChanged" object: number];
    
}

-(void)lg_didClickedAtIndex:(NSUInteger)index inPhotoBrowserView:(LGPhotoBrowserView* _Nonnull)photoBrowserView
{

}

#pragma mark - navigation delegate

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
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
    if ( operation == UINavigationControllerOperationPop )
    {
        return  [[LGSpringAnimator alloc]initWithOperation:operation from:(id<LGSpringAnimatorDelegate>)fromVC to:(id<LGSpringAnimatorDelegate>)toVC];
    }
    else
    {
        return nil;
    }
}

-(ImageAndFrame *)viewControllerAnimatorImageFrames
{
    LGPhotoBrowserView *view = (LGPhotoBrowserView*)self.view;
    return getDisplayingImageViewFrom(view);
}

@end
