//
//  LGPhotoBrowserConst.h
//  LGPhotoBrowser
//
//  Created by liaogang on 16/11/15.
//  Copyright © 2016年 liaogang. All rights reserved.
//

#ifndef LGPhotoBrowserConst_h
#define LGPhotoBrowserConst_h


/// use this flag show a number on cell for debug
#ifndef AS_SHOW_NUMBER
#define AS_SHOW_NUMBER 0
#endif

#if DEBUG
#else
#if AS_SHOW_NUMBER
#error "turn off this when release"
#endif
#endif



#endif /* LGPhotoBrowserConst_h */
