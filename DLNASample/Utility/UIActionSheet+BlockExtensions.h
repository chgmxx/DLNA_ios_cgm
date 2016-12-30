//
//  NSObject+UIActionSheet_BlockExtensions_h.h
//  GenieiPad
//
//  Created by liaogang on 8/25/14.
//
//



#import <UIKit/UIKit.h>
@interface UIActionSheet (BlockExtensions) <UIActionSheetDelegate>
- (id)initWithTitle:(NSString *)title completionBlock:(void (^)(NSUInteger buttonIndex, UIActionSheet *actionSheet))block cancelButtonTitle:(NSString *)cancelButtonTitle destructiveButtonTitle:(NSString *)destructiveButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ...;
@end