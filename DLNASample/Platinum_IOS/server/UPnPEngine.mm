//
//  UPnPEngine.m
//  demo
//
//  Created by geine on 6/16/15.
//  Copyright (c) 2015 com.cs. All rights reserved.
//

#import "UPnPEngine.h"
#import "util.h"
#import "Macro.h"
#import "PltMediaServerObjectMy.h"
#import "Reachability.h"



NSString *kNotifyDMSStopped = @"dms_stopped";

NSString *kNotifyDMSStarted = @"dms_started";

@interface UPnPEngine ()
{
    PLT_MediaServerObjectMy* rootServer;
    PLT_DeviceHostReference device;
}

@end


@implementation UPnPEngine

-(PLT_DeviceHostReference)getInner
{
    return device;
}

-(void)setup
{
    rootServer = [[PLT_MediaServerObjectMy alloc] initServerSelfDelegateWithServerName:@"Media Server"];
    
    device =[rootServer getDevice];
    
    UIImage *serverImage = [UIImage imageNamed:@"genie_dlna_render"];
    if (serverImage) {
        
        NSData* data =  UIImagePNGRepresentation(serverImage);
        
        PLT_DeviceIcon icon("image/png",152,152,32,"/genie_dlna_render.png");
        [rootServer getTheDevice]->AddIcon(icon, data.bytes , (NPT_Size)data.length );
    }
    else{
        NSLog(@"serverImage icon not finded.");
    }
    
}

-(instancetype)initPrivate
{
    self = [super init];
    if (self)
    {
        [self setup];
    }
    return self;
}

+ (instancetype)getEngine
{
    DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
        return [[self alloc] initPrivate];
    });
}

@end
