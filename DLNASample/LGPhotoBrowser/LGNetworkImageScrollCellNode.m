//
//  ASNetworkImageScrollCellNode.m
//  SDWebImage
//
//  Created by liaogang on 15/12/25.
//  Copyright © 2015年 liaogang. All rights reserved.
//

#import <LGPhotoBrowser/LGNetworkImageScrollCellNode.h>
#import <LGPhotoBrowser/LGPINRemoteImageDownloaderEx.h>


NSString *kLGPhotoBrowserSingleTapped = @"ASPhotoBrowserSingleTapped";

@interface LGNetworkImageScrollCellNode ()
<UIScrollViewDelegate,ASNetworkImageNodeDelegate>
@property (nonatomic,strong) ASScrollNode *scroll;
@property (nonatomic,strong) ASNetworkImageNode *imageNode;
@property (nonatomic,strong) NSURL *url;
@property (nonatomic,strong) UIActivityIndicatorView *ai;
@property (nonatomic,strong) UITapGestureRecognizer *doubleTap;
@end

@implementation LGNetworkImageScrollCellNode

-(instancetype)initWithURL:(NSURL*)url placeHodler:(UIImage*)placeHolder
{
    if (!(self = [super init]))
        return nil;
    
    _url = url;
    
    LGPINRemoteImageDownloaderEx *mng = [LGPINRemoteImageDownloaderEx sharedDownloader];
    
    _imageNode =[[ASNetworkImageNode alloc]initWithCache:mng downloader:mng];
    _imageNode.frame = self.bounds;
    _imageNode.contentMode = UIViewContentModeScaleAspectFit;
    _imageNode.clipsToBounds = YES;
    _imageNode.shouldCacheImage = YES;
    _imageNode.delegate = self;
    _imageNode.backgroundColor =[ UIColor clearColor];
    if (placeHolder) {
        _imageNode.defaultImage = placeHolder;
        _imageNode.placeholderEnabled = YES;
    }
    
    _scroll = [[ASScrollNode alloc] init];
    [_scroll addSubnode:_imageNode];
    _scroll.backgroundColor =[ UIColor clearColor];    
    
    
    [self addSubnode: _scroll ];
    
    return self;
}

- (void)handleSingleTap:(UITapGestureRecognizer *)tap {
    [[NSNotificationCenter defaultCenter] postNotificationName:kLGPhotoBrowserSingleTapped object:nil];
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)tap {
    UIScrollView *controller = _scroll.view;
    CGPoint touchPoint = [tap locationInView:controller];

    if (controller.zoomScale == controller.maximumZoomScale) {
        [controller setZoomScale:1.0 animated:YES];
    } else {
        [controller zoomToRect:CGRectMake(touchPoint.x, touchPoint.y, 1, 1) animated:YES];
    }
    
}


-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return _imageNode.view;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    // The scroll view has zoomed, so you need to re-center the contents
    [self centerScrollViewContents];
}

- (void)centerScrollViewContents {
    CGSize boundsSize = self.bounds.size;
    CGRect contentsFrame = self.imageNode.view.frame;

    if (contentsFrame.size.width < boundsSize.width) {
        contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0f;
    } else {
        contentsFrame.origin.x = 0.0f;
    }

    if (contentsFrame.size.height < boundsSize.height) {
        contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0f;
    } else {
        contentsFrame.origin.y = 0.0f;
    }

    self.imageNode.view.frame = contentsFrame;
}


- (void)layout
{
    [super layout];

    _scroll.frame = self.bounds;
    _imageNode.frame =  self.bounds;
    
    
    //test todo
    NSLog(@"cell bounds: %@", NSStringFromCGRect(self.bounds));
}

- (CGSize)calculateSizeThatFits:(CGSize)constrainedSize
{
    return constrainedSize;
}

-(void)startDownload
{
    // first display the transformed image from memory cache
    _imageNode.defaultImage = (UIImage *)[[LGPINRemoteImageDownloaderEx sharedTransformedDownloader] synchronouslyFetchedCachedImageWithURL: _url ];
    
    // set url and display
    _imageNode.URL = _url;
}

#pragma mark - ASNetworkImageNodeDelegate

-(void)imageNode:(ASNetworkImageNode *)imageNode didLoadImage:(UIImage *)image
{
    if (_doubleTap == nil)
    {
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
        singleTap.delaysTouchesBegan = YES;
        singleTap.numberOfTapsRequired = 1;
        
        [_scroll.view addGestureRecognizer:singleTap];
        
        
        _scroll.view.minimumZoomScale = 0.3;
        _scroll.view.maximumZoomScale = 3.0;
        _scroll.view.scrollEnabled = YES;
        _scroll.view.delegate = self;
        
        _doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
        _doubleTap.numberOfTapsRequired = 2;
        [_scroll.view addGestureRecognizer:_doubleTap];
        
        [singleTap requireGestureRecognizerToFail:_doubleTap];
    }

}

-(UIImage*)getImage
{
    return self.imageNode.image;
}

@end
