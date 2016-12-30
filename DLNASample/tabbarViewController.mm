//
//  tabbarViewController.m
//  DLNASample
//
//  Created by liaogang on 16/11/17.
//  Copyright © 2016年 liaogang. All rights reserved.
//

#import "tabbarViewController.h"
#import "DLNAHomeManager.h"
#import "DlnaControlPoint.h"


enum
{
    tab_index_source = 0,
    tab_index_control = 1,
};

@interface tabbarViewController ()
<DLNAHomeManagerDelegate,
ControlPointEventListener>
{
    NSUInteger lastServerCount;
    BOOL delayPopNavRoot;
}
@property (nonatomic,strong) DLNAHomeManager *mng;
@property (nonatomic,weak) UIViewController *presentedRender;
@end

@implementation tabbarViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.mng = [DLNAHomeManager shared];
    self.mng.delegate = self;
    
    [[DlnaControlPoint shared] addListener: self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dlnaManagerNeedPresentRenderer:(DLNAHomeManager *)mng
{
    if (self.presentedRender == nil)
    {
        
        UIViewController *rendererPane = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"rendererPane"];
        
        self.presentedRender = rendererPane;
        
        [self presentViewController:rendererPane animated:YES completion:^{
            [mng endPresentRenderer];
        }];
        
    }
    
}

-(void)dlnaManagerNeedDismissRenderer:(DLNAHomeManager*)mng
{
    [self.presentedRender dismissViewControllerAnimated:YES completion:nil];
    self.presentedRender = nil;
}

-(void)newRendererConnected:(DLNAHomeManager *)mng
{
    if (self.selectedIndex != tab_index_control )
    {
        UIViewController *vc = [self.viewControllers objectAtIndex:1];
        vc.tabBarItem.badgeValue = @"";
    }
    
}

-(void)eventComing:(event_name)event_type from:(DlnaControlPoint *)ctrlPoint
{
    if (event_type == event_media_server_list_changed) {
        
        //if the browing device is disappear , pop the navigation view controllers to root.
        if (ctrlPoint.currentServer == nil) {
            UINavigationController *deviceTabNav = self.viewControllers[tab_index_source];
            if (deviceTabNav.viewControllers.count > 1) {
                if (self.selectedIndex == tab_index_source) {
                    [deviceTabNav popToRootViewControllerAnimated:YES];
                }
                else{
                    delayPopNavRoot = YES;
                }
                
            }
            
        }
        
        
        
        if (self.selectedIndex == tab_index_source) {
        }
        else{
            NSInteger change = ctrlPoint.servers.count - lastServerCount;
            UIViewController *vc = [self.viewControllers objectAtIndex:0];
            vc.tabBarItem.badgeValue = [NSNumber numberWithInteger:change].stringValue;
        }
        
        
    }
    
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    if (item.badgeValue) {
        item.badgeValue = nil;
    }
    
    NSUInteger selectedIndex = [tabBar.items indexOfObject:item];
    if( selectedIndex == tab_index_source )
    {
        lastServerCount = [DlnaControlPoint shared].servers.count;
        
        if(delayPopNavRoot)
        {
            UINavigationController *deviceTabVC = self.viewControllers[tab_index_source];
            [deviceTabVC popToRootViewControllerAnimated:YES];
        }
        
    }
    
}

@end
