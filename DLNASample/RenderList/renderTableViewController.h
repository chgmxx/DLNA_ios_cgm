//
//  renderTableViewController.h
//  demo
//
//  Created by liaogang on 15/5/20.
//  Copyright (c) 2015年 com.cs. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol renderTableViewControllerDelegate;


/**You can get notify when a renderer is choosed.
 1.renderTableViewControllerDelegate
 2. throgh DlnaControlPoint's event_user_choosed_renderer
 */
@interface renderTableViewController : UITableViewController

@property (nonatomic,weak) id<renderTableViewControllerDelegate> delegate;

/**
 With this flag on, a cell selection will make effect,
 otherwise user must must use `Done` button.
 Default is NO.
 */
@property (nonatomic) BOOL oneClick;
           
@end


@protocol renderTableViewControllerDelegate <NSObject>
@required
-(void)rendererChanged:(NSUInteger)index;

@end
