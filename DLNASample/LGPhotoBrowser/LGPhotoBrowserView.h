//
//  ASPhotoBrowserController.h
//
//  Created by liaogang on 15/12/25.
//  Copyright © 2015年 liaogang. All rights reserved.
//

#import <UIKit/UIKit.h>



@protocol LGPhotoBrowserViewDataSource,LGPhotoBrowserViewDelegate;


@interface LGPhotoBrowserView : UIView

@property (nonatomic, weak, nullable) IBOutlet id <LGPhotoBrowserViewDelegate> lg_delegate;
@property (nonatomic, weak, nullable) IBOutlet id <LGPhotoBrowserViewDataSource> lg_dataSource;

-(void)reloadData;

-(void)clearCachedPhotoMemory;

-(NSUInteger)getPageIndex;

@end



@protocol LGPhotoBrowserViewDataSource <NSObject>
@required
-( NSUInteger )lg_numberOfItemsInPhotoBrowserView:(LGPhotoBrowserView* _Nonnull)photoBrowserView;

-( NSURL* _Nonnull )lg_urlForIndex:(NSUInteger)index inPhotoBrowserView:(LGPhotoBrowserView* _Nonnull)photoBrowserView;

-(NSUInteger)lg_firstIndexOfPhotoBrowserView:(LGPhotoBrowserView * _Nonnull)photoBrowserView;
@end

@protocol LGPhotoBrowserViewDelegate <NSObject>
@optional
-(void)lg_indexChanged:(NSUInteger)index inPhotoBrowserView:(LGPhotoBrowserView* _Nonnull)photoBrowserView;


-(void)lg_didClickedAtIndex:(NSUInteger)index inPhotoBrowserView:(LGPhotoBrowserView* _Nonnull)photoBrowserView;

@end
