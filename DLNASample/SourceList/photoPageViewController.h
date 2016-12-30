//
//  photoPageViewController.h
//  DLNASample
//
//  Created by liaogang on 16/11/17.
//  Copyright © 2016年 liaogang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CellDataA.h"

@interface photoPageViewController : UIViewController
@property (nonatomic) NSArray<CellDataA*>* cellsData;
@property (nonatomic) NSUInteger firstPageIndex;
@end

extern NSString *notifyPhotoBrowserViewController;
