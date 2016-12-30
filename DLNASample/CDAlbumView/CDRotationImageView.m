//
//  CDAlbumViewController.m
//  demo
//
//  Created by liaogang on 15/9/8.
//  Copyright (c) 2015年 com.cs. All rights reserved.
//

#import "CDRotationImageView.h"

UIImage * maskImage(UIImage *image ,UIImage *maskImage );

void resumeLayer(CALayer* layer);

void pauseLayer(CALayer * layer);


@interface CDRotationImageView ()
{
    bool setupDone;
}
@property (strong, nonatomic) UIImage *rotationImage;
@property (strong, nonatomic) UIImageView *imageCDBackgound;
@property (strong, nonatomic) UIImageView *imageCDFront;
@property (strong, nonatomic) UIImageView *imageAlbum;

@end

@implementation  CDRotationImageView

-(void)setup
{
    UIImageView *imageView;
    imageView = [[UIImageView alloc] initWithFrame:self.bounds];
    imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:imageView];
    self.imageCDBackgound = imageView;
    
    imageView = [[UIImageView alloc] initWithFrame:self.bounds];
    imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:imageView];
    self.imageCDFront = imageView;
    
    imageView = [[UIImageView alloc] initWithFrame:self.bounds];
    imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:imageView];
    self.imageAlbum = imageView;
}

-(UIImage*)getImage
{
    return _rotationImage;
}

-(void)setImage:(UIImage *)image
{
    _rotationImage = image;
    
   
    if (setupDone) {
        [self setImageAndRotation];
    }
    //else will be done in layoutsubviews
   
}


-(void)setImageAndRotation
{
    if ( _rotationImage )
    {
        self.imageCDFront.hidden = YES;
        self.imageAlbum.hidden = NO;
        
        UIImage *mask = [UIImage imageNamed:@"cd_mask"];
        self.imageAlbum.image = maskImage( self.rotationImage , mask);
    }
    else
    {
        self.imageCDFront.hidden = NO;
        self.imageAlbum.hidden = YES;
        self.imageAlbum.image = nil;
    }
     
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    if ( setupDone == FALSE  )
    {
        [self setup];
        setupDone = TRUE;
        
        [self setImageAndRotation];
    }
    
    CGFloat width = self.bounds.size.width;
    CGFloat radius = width;
    
    self.imageAlbum.layer.cornerRadius = radius / 2.;
    self.imageCDFront.layer.cornerRadius = radius / 2.;
    self.imageCDBackgound.layer.cornerRadius = radius / 2.;
    
    self.imageCDFront.layer.masksToBounds = YES;
    self.imageAlbum.layer.masksToBounds = YES;
    self.imageCDBackgound.layer.masksToBounds = YES;
}

-(BOOL)isRotating
{
    return self.imageAlbum.layer.speed > 0.0;
}

-(void)endRotation
{
    self.suppressedByTouch = false;
    pauseLayer(self.imageAlbum.layer);
}

-(void)startRotation
{
    if([self.imageAlbum.layer animationForKey:@"rotationAnimation"] )
        [self _startAlbumRotation];
    else
        [self performSelector:@selector(_startAlbumRotation) withObject:nil afterDelay:0.9];
}


-(void)_startAlbumRotation
{
    if(![self.imageAlbum.layer animationForKey:@"rotationAnimation"] )
    {
        CFTimeInterval duration = 100 * 10 * 60 ;
        CABasicAnimation* rotationAnimation;
        rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0 /* full rotation*/ * 0.15  * duration ];
        rotationAnimation.duration = duration;
        rotationAnimation.cumulative = YES;
        rotationAnimation.repeatCount = 1;
        
        [self.imageAlbum.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
    }
    
    resumeLayer(self.imageAlbum.layer);
}


#pragma mark - touches

-(void)imageTouchesEnded
{
    if (self.suppressedByTouch ) {
        [self _startAlbumRotation];
        self.suppressedByTouch = false;
    }
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ([self isRotating]) {
        [self endRotation];
        self.suppressedByTouch = true;
    }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self imageTouchesEnded];
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self imageTouchesEnded];
}

@end


void pauseLayer(CALayer * layer)
{
    if (layer.speed > 0.0)
    {
        CFTimeInterval pausedTime = [layer convertTime:CACurrentMediaTime() fromLayer:nil];
        layer.speed = 0.0;
        layer.timeOffset = pausedTime;
    }
}

void resumeLayer(CALayer* layer)
{
    if (layer.speed == 0.0)
    {
        CFTimeInterval pausedTime = [layer timeOffset];
        layer.speed = 1.0;
        layer.timeOffset = 0.0;
        layer.beginTime = 0.0;
        CFTimeInterval timeSincePause = [layer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
        layer.beginTime = timeSincePause;
    }
}


UIImage * maskImage(UIImage *image ,UIImage *maskImage )
{
    CGImageRef maskRef = maskImage.CGImage;
    
    CGImageRef mask = CGImageMaskCreate(CGImageGetWidth(maskRef),
                                        CGImageGetHeight(maskRef),
                                        CGImageGetBitsPerComponent(maskRef),
                                        CGImageGetBitsPerPixel(maskRef),
                                        CGImageGetBytesPerRow(maskRef),
                                        CGImageGetDataProvider(maskRef), NULL, false);
    
    CGImageRef maskedImageRef = CGImageCreateWithMask([image CGImage], mask);
    UIImage *maskedImage = [UIImage imageWithCGImage:maskedImageRef];
    
    CGImageRelease(mask);
    CGImageRelease(maskedImageRef);
    
    // returns new image with mask applied
    return maskedImage;
}




