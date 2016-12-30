//
//  LGSpringPushAnimator.h
//  LGPhotoBrowser
//
//  Created by liaogang on 16/11/11.
//  Copyright © 2016年 liaogang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@protocol LGSpringAnimatorDelegate;


///  push another view from LGCollectionView
@interface LGSpringAnimator : NSObject
<UIViewControllerAnimatedTransitioning>

-(instancetype)initWithOperation:(UINavigationControllerOperation)operation from:(id<LGSpringAnimatorDelegate>) fromViewController to:(id<LGSpringAnimatorDelegate>)toViewController;

@end



@class ImageAndFrame;
/// the push spring animator animated from left to right
/// the pop spring ,the other way
@protocol LGSpringAnimatorDelegate <NSObject>

-(ImageAndFrame*)viewControllerAnimatorImageFrames;

@end



@interface ImageAndFrame : NSObject
@property (nonatomic,strong)   UIImage *image;
@property (nonatomic) CGRect frame;
@end

@class LGCollectionView,LGPhotoBrowserView;

#if defined(__cplusplus)
extern "C" {
#endif
    
ImageAndFrame *getShowingImageViewFrom(LGCollectionView *view);
ImageAndFrame *getDisplayingImageViewFrom(LGPhotoBrowserView *view);

#if defined(__cplusplus)
}
#endif