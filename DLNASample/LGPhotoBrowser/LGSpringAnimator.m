//
//  LGSpringPushAnimator.m
//  LGPhotoBrowser
//
//  Created by liaogang on 16/11/11.
//  Copyright © 2016年 liaogang. All rights reserved.
//

#import <LGPhotoBrowser/LGSpringAnimator.h>
#import <LGPhotoBrowser/LGCollectionView.h>
#import <LGPhotoBrowser/LGNetworkImageCellNode.h>
//#import "VICMAImageView/VICMAImageView.h"

const int imageTag = 10324;

const NSTimeInterval push_duration = 0.55;
const CGFloat push_damping = 0.76;
const CGFloat push_initialVelocity = 0.48;

const NSTimeInterval pop_duration = 0.4;
const CGFloat pop_damping = 0.9;
const CGFloat pop_initialVelocity = 0.4;


@interface LGSpringAnimator ()
{
    UINavigationControllerOperation _operation;
}

@property (nonatomic,weak) id<LGSpringAnimatorDelegate> fromViewController,toViewController;

@end

@implementation LGSpringAnimator

-(instancetype)initWithOperation:(UINavigationControllerOperation)operation from:(id<LGSpringAnimatorDelegate>)fromViewController to:(id<LGSpringAnimatorDelegate>)toViewController
{
    self = [super init];
    if (self) {
    
        _operation = operation;
        _fromViewController = fromViewController;
        _toViewController = toViewController;
        
    }
    
    return self;
}

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
    return _operation == UINavigationControllerOperationPush ? push_duration: pop_damping;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController* fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController* toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    toViewController.view.frame = [transitionContext finalFrameForViewController:toViewController];
    [[transitionContext containerView] addSubview:toViewController.view];
    
    NSAssert([_fromViewController respondsToSelector:@selector(viewControllerAnimatorImageFrames)], @"");
    NSAssert([_toViewController respondsToSelector:@selector(viewControllerAnimatorImageFrames)], @"");

    ImageAndFrame *fromImageFrame,*toImageFrame;
    fromImageFrame = [_fromViewController viewControllerAnimatorImageFrames];
    toImageFrame = [_toViewController viewControllerAnimatorImageFrames];

    
    
    // the key image view.
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:fromImageFrame.frame ];
    imageView.backgroundColor = [UIColor clearColor];
    
    if ( _operation == UINavigationControllerOperationPop) {
        [imageView setContentMode: UIViewContentModeScaleAspectFill];
        imageView.clipsToBounds = YES;
        [imageView setImage: toImageFrame.image];
    }
    else{
        [imageView setImage: fromImageFrame.image];
        [imageView setContentMode: UIViewContentModeScaleAspectFill];
    }
    
    imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    imageView.tag = imageTag;
    
    [fromViewController.view addSubview:imageView];
    toViewController.view.alpha = 0;

    
    
    
    CGFloat dampling;
    CGFloat initialVelocity;
    if (_operation == UINavigationControllerOperationPush) {
        dampling = push_damping ;
        initialVelocity = push_initialVelocity ;
    }
    else {
        dampling = pop_damping ;
        initialVelocity = pop_initialVelocity ;
    }
    
    [UIView animateWithDuration: [self transitionDuration:transitionContext]                         delay:0
         usingSpringWithDamping: dampling
          initialSpringVelocity: initialVelocity
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         imageView.frame = toImageFrame.frame;
                         
                         if (_operation == UINavigationControllerOperationPop)
                         {
                             toViewController.view.alpha = 1;
                         }
                         else{
                             imageView.backgroundColor = [UIColor whiteColor];
                         }
                         
                     } completion:^(BOOL finished) {
                         toViewController.view.alpha = 1;
                         [imageView removeFromSuperview];
                         [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
                     }];
    
    
    
}

@end






@implementation ImageAndFrame

@end

