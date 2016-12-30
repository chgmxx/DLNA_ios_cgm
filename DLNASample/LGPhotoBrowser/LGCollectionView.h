//
//  ASCollectionController.h
//  SDWebImage
//
//  Created by liaogang on 15/12/24.
//  Copyright © 2015年 liaogang. All rights reserved.
//

#import <UIKit/UIKit.h>




@class ASAnimator;
@protocol ASCollectionViewControllerDelegate;
@protocol ASCollectionViewControllerDataSource;
@protocol LGCollectionViewDataSource;
@protocol LGCollectionViewDelegate;

@interface LGCollectionView : UIView

@property (nonatomic, weak, nullable) IBOutlet id <LGCollectionViewDelegate> delegate;
@property (nonatomic, weak, nullable) IBOutlet id <LGCollectionViewDataSource> dataSource;

-(NSUInteger)selectedIndex;

@property (nonatomic,strong,nullable) UIImage *  placeHolder;

-(void)scrolltoAndSelectIndex:(NSUInteger)index;


-(void)reloadData;

-(void)clearPhotoCachedMemory;

@end



@protocol LGCollectionViewDataSource <NSObject>

@required
-( NSUInteger )lg_numberOfItemsInCollectionView:(LGCollectionView* _Nonnull)collectionView;

-( NSURL* _Nonnull )lg_urlForIndex:(NSUInteger)index inCollectionView:(LGCollectionView* _Nonnull)collectionView;

@end


@protocol LGCollectionViewDelegate <NSObject>
@optional

-(void)lg_collectionView:(LGCollectionView* _Nonnull)collectionView didClickedAtIndex:(NSUInteger)index;

@end


