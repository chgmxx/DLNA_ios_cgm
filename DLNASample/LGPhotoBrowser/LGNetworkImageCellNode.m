//
//  ASNetworkImageCellNode.m
//  SDWebImage
//
//  Created by liaogang on 15/12/24.
//  Copyright © 2015年 liaogang. All rights reserved.
//


#import <LGPhotoBrowser/LGNetworkImageCellNode.h>
#import <LGPhotoBrowser/LGPINRemoteImageDownloaderEx.h>



#define Use_PlaceHolder


@interface LGNetworkImageCellNode ()
<ASNetworkImageNodeDelegate>
{
    bool imageLoaded;
}
@property (nonatomic,strong) ASNetworkImageNode *imageNode;
@property (nonatomic,strong) NSURL *url;
#if AS_SHOW_NUMBER
@property (nonatomic,strong) UILabel *label;
#endif
@property (nonatomic,strong) UIImage *image;
@end

@implementation LGNetworkImageCellNode


-(instancetype)initWithURL:(NSURL*)url contentMode:(UIViewContentMode)mode placeHodler:(UIImage*)placeHolder
{
    if (!(self = [super init]))
        return nil;
    
    _url = url;
    
    LGPINRemoteImageDownloaderEx *mng = [LGPINRemoteImageDownloaderEx sharedTransformedDownloader];
    
    _imageNode =[[ASNetworkImageNode alloc]initWithCache:mng downloader:mng];
    _imageNode.frame = self.bounds;
    _imageNode.contentMode = mode;
    _imageNode.clipsToBounds = YES;
    _imageNode.shouldCacheImage = YES;
    _imageNode.delegate = self;
    if (placeHolder) {
        _imageNode.defaultImage = placeHolder;
        _imageNode.placeholderEnabled = YES;
    }
    
    [self addSubnode:_imageNode];
    
    
#if AS_SHOW_NUMBER
    _label = [[UILabel alloc]init];
    _label.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_label];
#endif
    
    return self;
}

#if AS_SHOW_NUMBER
-(void)setTheText:(NSString*)s
{
    _label.text = s;
    
}
#endif

- (void)layout
{
    [super layout];
    
    _imageNode.frame = self.bounds;
    
#if AS_SHOW_NUMBER
    _label.frame = self.bounds;
#endif
}

- (CGSize)calculateSizeThatFits:(CGSize)constrainedSize
{
    return constrainedSize;
}

-(void)startDownload
{
    _imageNode.URL = _url;
}

#pragma mark - ASNetworkImageNodeDelegate

-(void)imageNode:(ASNetworkImageNode *)imageNode didLoadImage:(UIImage *)image
{
    self.image = image;
    imageLoaded = true;
    [self showImageView];
}

-(UIImage*)getImage
{
    return self.image;
}

-(bool)imageLoaded
{
    return imageLoaded;
}

-(void)showImageView
{
    if (_imageNode.placeholderImage )
    {
    }
    else
    {
        [_imageNode.view setAlpha:0.0f];
        
        
        [UIView animateWithDuration:0.5 animations:^{
            [_imageNode.view setAlpha:1.0f];
        } completion:^(BOOL finished) {
            
            
        }];
    }
    
}


@end
