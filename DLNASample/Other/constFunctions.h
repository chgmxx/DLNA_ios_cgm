//
//  constFunctions.m
//  demo
//
//  Created by liaogang on 15/9/17.
//  Copyright (c) 2015年 com.cs. All rights reserved.
//

#import <Foundation/Foundation.h>
@class UIView;



NSString* uintSizeDescription(long long size);

/**return the current languages iso code.
 * but zh_CN for simple chinese
 *     zh_TW for traditional
 */
NSString *getCurrLanguagesOfDevice();

/**
 @return true if is UserInterface Idiom is Pad
 */
bool curDeviceIsPad();


#if defined(__cplusplus)
extern "C" {
#endif
NSString * UIKitLocalizedString(NSString *key);
#if defined(__cplusplus)
}
#endif


void showMessageInCentreOfView(UIView* view,NSString* msg);
void hideMessageInCentreOfView(UIView* view);
