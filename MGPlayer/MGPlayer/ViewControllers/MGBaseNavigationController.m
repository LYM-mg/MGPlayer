//
//  MGBaseNavigationController.m
//  MGPlayer
//
//  Created by ming on 16/6/3.
//  Copyright © 2016年 ming. All rights reserved.
//

#import "MGBaseNavigationController.h"

@interface MGBaseNavigationController ()

@end

@implementation MGBaseNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    //    if( ([[UIDevice currentDevice].systemVersion floatValue]>=7.0)) {
    //        self.edgesForExtendedLayout=UIRectEdgeNone;//下移64
    //        self.navigationBar.translucent = NO;
    //    }
    self.navigationBar.barTintColor = [UIColor redColor];
    //返回按钮颜色
    UIImage *backButtonImage = [[UIImage imageNamed:@"navigator_btn_back"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 30, 0, 0)];
    [[UIBarButtonItem appearance] setBackButtonBackgroundImage:backButtonImage forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    
    self.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationBar.titleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor],NSForegroundColorAttributeName,[UIFont boldSystemFontOfSize:17.0],NSFontAttributeName ,nil];
}
-(void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated{
    if (self.viewControllers.count) {
        viewController.hidesBottomBarWhenPushed = YES;
    }
    [super pushViewController:viewController animated:animated];
}
/**
 *  导航控制器 统一管理状态栏颜色
 *  @return 状态栏颜色
 */
-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}


@end
