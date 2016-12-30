//
//  CDAlbumViewController.h
//  demo
//
//  Created by liaogang on 15/9/8.
//  Copyright (c) 2015年 com.cs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface  CDRotationImageView : UIImageView

-(void)startRotation;

-(void)endRotation;

-(BOOL)isRotating;

//do not rotate when user touched.
@property (nonatomic) BOOL suppressedByTouch;

@end




