//
//  ASPhotoBrowserController.m
//
//  Created by liaogang on 15/12/25.
//  Copyright © 2015年 liaogang. All rights reserved.
//

#import <LGPhotoBrowser/LGPhotoBrowserView.h>
#import <LGPhotoBrowser/LGPhotoBrowserConst.h>
#import <LGPhotoBrowser/LGNetworkImageScrollCellNode.h>
#import <LGPhotoBrowser/LGSpringAnimator.h>
#import <LGPhotoBrowser/LGNetworkImageCellNode.h>
#import <LGPhotoBrowser/LGPINRemoteImageDownloaderEx.h>
#import <AsyncDisplayKit/AsyncDisplayKit.h>




@interface LGPhotoBrowserView ()
< ASPagerDataSource,
ASPagerDelegate>
{
    NSUInteger rows;
    bool _loaded;
}
@property (nonatomic,strong) ASPagerNode * _Nonnull pagerNode;
@property (nonatomic,strong) ASPagerFlowLayout *flowLayout;
@property (nonatomic) NSUInteger index;

@end


@implementation LGPhotoBrowserView

const int kPadding = 10;

- (void)setup
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(singleTapped) name:kLGPhotoBrowserSingleTapped object:nil];
    
    
    _flowLayout = [[ASPagerFlowLayout alloc] init];
    _flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    _flowLayout.sectionInset = UIEdgeInsetsMake( 0 , kPadding, 0 , kPadding);
    _flowLayout.minimumInteritemSpacing = 0;
    _flowLayout.minimumLineSpacing = kPadding * 2;
    _flowLayout.itemSize = self.bounds.size;
    
    self.pagerNode = [[ASPagerNode alloc] initWithCollectionViewLayout:_flowLayout];
    self.pagerNode.dataSource = self;
    self.pagerNode.delegate = self;
    self.pagerNode.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    CGRect frame = self.bounds;
    frame.origin.x -= kPadding;
    frame.size.width += (2 * kPadding);
    self.pagerNode.frame = frame;
    self.backgroundColor = self.backgroundColor;
    self.pagerNode.view.zeroContentInsets = YES;
//    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:self.pagerNode.view];
    
    
    NSAssert(self.lg_dataSource, @"complete datasource protocal first.");
    rows = [self.lg_dataSource lg_numberOfItemsInPhotoBrowserView: self ];
    
    [self.pagerNode reloadDataWithCompletion:^{
        
        self.index = [self.lg_dataSource lg_firstIndexOfPhotoBrowserView:self];
        
        [self scrollToPageAtIndex:self.index animated: NO ];
    }];
    
}




-(void)layoutSubviews
{
    [super layoutSubviews];
    
    if (_loaded == false) {
        _loaded = true;
        
        [self setup];
    }
    else{
        
        CFTimeInterval max = 0;
        for ( NSString *key in self.layer.animationKeys) {
            CAAnimation *animation = [self.layer animationForKey:key];
            if (animation.duration > max) {
                max = animation.duration;
            }
        }
        
        NSLog(@"max: %f",max);
        max += 1;
        
        [self performSelector:@selector(updateLayout) withObject:nil afterDelay:max];
    }
    
}

-(void)updateLayout
{
    
    _flowLayout.itemSize = self.bounds.size;
    [self.pagerNode setNeedsLayout];
    
    
    CGRect frame = self.bounds;
    frame.origin.x -= kPadding;
    frame.size.width += (2 * kPadding);
    self.pagerNode.frame = frame;
    
    
    
    NSLog(@"photo browser frame: %@", NSStringFromCGRect(self.frame));
    
    NSLog(@"photo browser page node frame: %@", NSStringFromCGRect(self.pagerNode.frame));
}


- (void)scrollToPageAtIndex:(NSInteger)index animated:(BOOL)animated
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
    [self.pagerNode.view scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated: NO];
}

-(void)singleTapped
{
    if ([self.lg_delegate respondsToSelector:@selector(lg_didClickedAtIndex:inPhotoBrowserView:)])
    {
        [self.lg_delegate lg_didClickedAtIndex: self.index inPhotoBrowserView:self];
    }
    
}

///photo size is the same as view bounds
-(ASSizeRange)pagerNode:(ASPagerNode *)pagerNode constrainedSizeForNodeAtIndexPath:(NSIndexPath *)indexPath
{
    return ASSizeRangeMake(CGSizeZero, self.bounds.size);
}

-(void)indexChanged
{
    [self.pagerNode.view setContentOffset:CGPointMake( CGRectGetWidth( self.bounds ) * _index , 0) animated:NO];
}

-(NSUInteger)getPageIndex
{
    return self.index;
}

-(void)reloadData
{
    rows = [self.lg_dataSource lg_numberOfItemsInPhotoBrowserView:self];
    
    [self reloadData];
}


-(void)clearCachedPhotoMemory
{
    [[LGPINRemoteImageDownloaderEx sharedDownloader] clearMemory];
}

#pragma mark - pagerNode data source.

-(ASCellNode *)pagerNode:(ASPagerNode *)pagerNode nodeAtIndex:(NSInteger)index
{
    NSURL *url = [self.lg_dataSource lg_urlForIndex:index inPhotoBrowserView:self] ;
                                                                              
    LGNetworkImageScrollCellNode *n = [[LGNetworkImageScrollCellNode alloc]initWithURL:url placeHodler: nil ];
    
    return n;
}


-(void)startDownload:(NSUInteger)index
{
    if ( index < rows) {
        LGNetworkImageScrollCellNode *node = (LGNetworkImageScrollCellNode*)[self.pagerNode nodeForPageAtIndex:index];
        [node startDownload];
    }
}


- (void)collectionView:(ASCollectionView *)collectionView willDisplayNodeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger row = indexPath.row;
    
    
    [self startDownload: row];
    
    
    // load the next too
    [self startDownload: row-1];
    [self startDownload: row+1];
    [self startDownload: row+2];
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    NSInteger index_ = self.pagerNode.currentPageIndex;
    
    if ( 0 <= index_ && index_ < rows ) {
        if (index_ != _index) {
            _index = index_;
            if (self.lg_delegate && [self.lg_delegate respondsToSelector:@selector(lg_indexChanged:inPhotoBrowserView:)])
            {
                [self.lg_delegate lg_indexChanged:index_ inPhotoBrowserView:self];
            }
        }
    }
    
    
}


// figure out where the scrolling will stop,load the image there
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    int x = targetContentOffset->x;
    int cellW = CGRectGetWidth(self.bounds);
    
    int row = x / cellW;
    

    [self startDownload: row];
}

-(NSInteger)numberOfPagesInPagerNode:(ASPagerNode *)pagerNode
{
    return rows;
}


- (void)collectionViewLockDataSource:(ASCollectionView *)collectionView
{
    // lock the data source
    // The data source should not be change until it is unlocked.
}

- (void)collectionViewUnlockDataSource:(ASCollectionView *)collectionView
{
    // unlock the data source to enable data source updating.
    NSLog(@"collectionViewUnlockDataSource");
    
}

- (void)collectionView:(UICollectionView *)collectionView willBeginBatchFetchWithContext:(ASBatchContext *)context
{
    [context completeBatchFetching:YES];
}


@end




ImageAndFrame *getDisplayingImageViewFrom(LGPhotoBrowserView *view)
{
    ImageAndFrame *result = [[ImageAndFrame alloc]init];
    
    NSInteger index = view.pagerNode.currentPageIndex;
    
    LGNetworkImageCellNode *cell = (LGNetworkImageCellNode*)[view.pagerNode nodeForPageAtIndex: index];

    result.image = [cell getImage];
    result.frame =  view.bounds;
    
    return result;
}






