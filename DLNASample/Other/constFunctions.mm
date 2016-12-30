//
//  constFunctions.m
//  demo
//
//  Created by liaogang on 15/9/17.
//  Copyright (c) 2015年 com.cs. All rights reserved.
//

#import "constFunctions.h"
#import "constDefines.h"
#import "MAAssert.h"
#import <Platinum/Platinum.h>

NSString *secondDescription(NPT_UInt32 seconds)
{
    int minutes = seconds / 60;
    int hours = minutes / 60;
    
    int minute = ( seconds - hours * 60 )/60;
    int second = seconds - minutes * 60;
    
    if (hours == 0)
        return [NSString stringWithFormat:@"%02d:%02d",minute,second];
    
    return  [NSString stringWithFormat:@"%02d:%02d:%02d",hours,minute,second];
}

NSString *getCurrLanguagesOfDevice()
{
    NSString * code = [[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"][0];
    
    if ([code isEqualToString:@"zh-Hans" ])
    {
        return @"zh_CN";
    }
    else if([code isEqualToString:@"zh-Hant"] )
    {
        return @"zh_TW";
    }
    
    return code;
}


bool curDeviceIsPad()
{
    static bool bPad;
    static bool first = true;
    if (first) {
        first = false;
        bPad = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad;
    }
    
    return bPad;
}

NSString * UIKitLocalizedString(NSString *key)
{
    NSString *result = [[NSBundle bundleWithIdentifier:@"com.apple.UIKit"] localizedStringForKey:key value:@"" table:nil];
    MAAssert(result, @"can not find the localized string in UIKit bundle for key: %@",key);
    return result;
}



const NSUInteger tag = 1293;

void showMessageInCentreOfView(UIView* view,NSString* msg)
{
    UILabel * label = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, CGRectGetWidth(view.bounds) , 40)];
    label.center=  view.center;
    
    label.autoresizingMask =  UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    label.textAlignment = NSTextAlignmentCenter;
    label.text= msg;
    label.textColor = [UIColor colorWithRed:142/255.0 green:142/255.0 blue:147/255.0 alpha:1];
    label.tag = tag;
    [view addSubview:label];
}

void hideMessageInCentreOfView(UIView* view)
{
    UILabel *label = [view viewWithTag:tag];
    [label removeFromSuperview];
}

