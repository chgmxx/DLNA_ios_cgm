//
//  constDefines.h
//  demo
//
//  Created by liaogang on 15/9/7.
//  Copyright (c) 2015年 com.cs. All rights reserved.
//

#ifndef demo_constDefines_h
#define demo_constDefines_h

#import <UIKit/UIKit.h>


extern NSString * const kNotifyPresentModal;

typedef void (^done)(void);

typedef void(^CallbackDataDirty)(int section);

extern const char* source_names[];


enum MediaType
{
    Unknown,
    Video,
    Folder,
    Photo,
    Music,
    Normal
};

#endif
