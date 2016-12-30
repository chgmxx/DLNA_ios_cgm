//
//  asyncCollectionController.m
//  SDWebImage
//
//  Created by liaogang on 15/12/24.
//  Copyright © 2015年 liaogang. All rights reserved.
//


#import <LGPhotoBrowser/LGPhotoBrowserConst.h>
#import <LGPhotoBrowser/LGCollectionView.h>
#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import <LGPhotoBrowser/LGNetworkImageCellNode.h>
#import <PINRemoteImage/PINRemoteImageCategoryManager.h>
#import <LGPhotoBrowser/LGNetworkImageScrollCellNode.h>
#import <LGPhotoBrowser/LGPhotoBrowserConst.h>
#import <LGPhotoBrowser/LGPINRemoteImageDownloaderEx.h>
#import <LGPhotoBrowser/LGSpringAnimator.h>


@interface LGCollectionView ()
<ASCollectionViewDataSource, ASCollectionViewDelegate,
UINavigationControllerDelegate>
@property (nonatomic) NSInteger selectedRow;
@property (nonatomic,strong) UICollectionViewFlowLayout *layout;
@property (nonatomic,strong) ASCollectionView *collectionView;
@end

@implementation LGCollectionView


-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self =[super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

-(instancetype)initWithFrame:(CGRect)frame
{
    self =[super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    _selectedRow = -1;
    
    _layout = [[UICollectionViewFlowLayout alloc] init];
    [self rescaleLayout];
    
    
    _collectionView = [[ASCollectionView alloc] initWithFrame: self.bounds collectionViewLayout:_layout ];
    self.collectionView.asyncDataSource = self;
    self.collectionView.asyncDelegate = self;
    self.collectionView.zeroContentInsets = YES;
    self.collectionView.alwaysBounceVertical = YES;
    
    self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:_collectionView];
    
}

-(UIView*)cellForIndex:(NSIndexPath*)indexPath
{
    return [self.collectionView nodeForItemAtIndexPath:indexPath].view;
}

-(void)layoutSubviews
{
    [self rescaleLayout];
    
    [self.collectionView.collectionViewLayout invalidateLayout];
}


-(void)rescaleLayout
{
    _layout.sectionInset = UIEdgeInsetsMake(4, 4, 4, 4);
    _layout.minimumInteritemSpacing = 4;
    _layout.minimumLineSpacing = 4;
    
    
    CGFloat column_count;
    if ( [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        column_count = 4;
    }
    else
    {
        column_count = 3;
    }
    
    
    CGFloat width =  self.bounds.size.width - _layout.minimumInteritemSpacing * ( column_count - 1) - _layout.sectionInset.left - _layout.sectionInset.right ;
    width = width / column_count;
    width -= 1;
    
    
    _layout.itemSize =  CGSizeMake(width, width);
    
    
    LGPINRemoteImageDownloaderEx *mng = [LGPINRemoteImageDownloaderEx sharedTransformedDownloader];

    [mng setScaleSize: self.bounds.size ];

}

-(void)clearPhotoCachedMemory
{
    [[LGPINRemoteImageDownloaderEx sharedTransformedDownloader] clearMemory];
    [[LGPINRemoteImageDownloaderEx sharedDownloader] clearMemory];
}


-(void)dealloc
{
    [self clearPhotoCachedMemory];
}

#pragma mark - ASCollectionView data source.

- (ASCellNode *)collectionView:(ASCollectionView *)collectionView nodeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSURL *url = [self.dataSource lg_urlForIndex:indexPath.row inCollectionView:self];
    
    
    LGNetworkImageCellNode *n = [[LGNetworkImageCellNode alloc]initWithURL:url contentMode: UIViewContentModeScaleAspectFill placeHodler: _placeHolder ];
    
    
#if AS_SHOW_NUMBER
    [n setTheText: @(indexPath.row+1).stringValue];
#endif
    
    
    return n;
}


- (void)collectionView:(ASCollectionView *)collectionView willDisplayNodeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;

    [self startDownload: (int)row];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSAssert(self.dataSource, @"data source null.");
    return [self.dataSource lg_numberOfItemsInCollectionView:self];
}


-(void)startDownload:(int)index
{
    LGNetworkImageCellNode *node = (LGNetworkImageCellNode*)[self.collectionView nodeForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
    [node startDownload];
}



-(NSUInteger)selectedIndex
{
    return _selectedRow;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(lg_collectionView:didClickedAtIndex:)]) {
        _selectedRow = indexPath.row;
        [self.delegate lg_collectionView:self didClickedAtIndex:indexPath.row];
    }
}


-(void)scrolltoAndSelectIndex:(NSUInteger)index
{
    [self scrollToIndex:index];
    _selectedRow = index;
}

-(void)scrollToIndex:(NSUInteger)index
{
    NSIndexPath *indexPath =[NSIndexPath indexPathForRow:index inSection:0];
    
    bool needscroll = true;
    NSArray<NSIndexPath *> *paths = [self.collectionView indexPathsForVisibleItems];
    for (NSIndexPath *path in paths) {
        if (path.row == index) {
            needscroll = false;
            break;
        }
    }
    
    
    if (needscroll)
    {
        UICollectionViewScrollPosition pos;
        NSIndexPath *path = paths.firstObject;
        if ( index >  path.row) {
            pos = UICollectionViewScrollPositionBottom;
        }
        else{
            pos = UICollectionViewScrollPositionTop;
        }

        [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:pos animated:NO];
    }
    
}

-(void)reloadData
{
    [self.collectionView reloadData];
}

@end




ImageAndFrame *getShowingImageViewFrom(LGCollectionView *view)
{
    ImageAndFrame *iaf = [[ImageAndFrame alloc]init];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[view selectedIndex] inSection:0];
    
    LGNetworkImageCellNode *cell = (LGNetworkImageCellNode*)[view.collectionView nodeForItemAtIndexPath: indexPath ];
    
    UICollectionViewLayoutAttributes *attributes = [view.collectionView layoutAttributesForItemAtIndexPath:indexPath];
    CGRect cellFrameWithOffset = attributes.frame;
    
    CGPoint offset = view.collectionView.contentOffset;
    
    CGRect cellFrame = CGRectMake(cellFrameWithOffset.origin.x - offset.x, cellFrameWithOffset.origin.y - offset.y, cellFrameWithOffset.size.width, cellFrameWithOffset.size.height);

    
    iaf.frame = cellFrame;
    iaf.image = [cell getImage];
    
    return iaf;
}

