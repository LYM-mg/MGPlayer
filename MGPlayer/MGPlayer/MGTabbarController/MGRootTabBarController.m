//
//  MGRootTabBarController.m
//  MGPlayer
//
//  Created by ming on 16/6/3.
//  Copyright © 2016年 ming. All rights reserved.
//

#import "MGRootTabBarController.h"

#import "MGTencentNewsViewController.h"
#import "MGSinaNewsViewController.h"
#import "MGNetEaseViewController.h"
#import "MGBaseNavigationController.h"

@interface MGRootTabBarController ()

@end

@implementation MGRootTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setUpTabBarChildController];
}

- (void)setUpTabBarChildController{
    MGTencentNewsViewController *tencentVC = [[MGTencentNewsViewController alloc]init];
    tencentVC.title = @"腾讯";
    MGBaseNavigationController *tencentNav = [[MGBaseNavigationController alloc]initWithRootViewController:tencentVC];
    tencentNav.tabBarItem = [[UITabBarItem alloc]initWithTitle:@"腾讯" image:[UIImage imageNamed:@"found@2x.png"] selectedImage:[UIImage imageNamed:@"found_s@2x.png"]];
    tencentNav.navigationBar.barTintColor = [UIColor redColor];
    
    
    
    MGSinaNewsViewController *sinaVC = [[MGSinaNewsViewController alloc] init];
    sinaVC.title = @"新浪";
    MGBaseNavigationController *sinaNav = [[MGBaseNavigationController alloc] initWithRootViewController:sinaVC];
    sinaNav.tabBarItem = [[UITabBarItem alloc]initWithTitle:@"新浪" image:[UIImage imageNamed:@"message@2x.png"] selectedImage:[UIImage imageNamed:@"message_s@2x.png"]];
    
    
    
    MGNetEaseViewController *netEaseVC = [[MGNetEaseViewController alloc] init];
    netEaseVC.title = @"网易";
    MGBaseNavigationController *netEaseNav = [[MGBaseNavigationController alloc] initWithRootViewController:netEaseVC];
    netEaseNav.tabBarItem = [[UITabBarItem alloc]initWithTitle:@"网易" image:[UIImage imageNamed:@"share@2x.png"] selectedImage:[UIImage imageNamed:@"share_s@2x.png"]];
    
    self.viewControllers = @[tencentNav,sinaNav,netEaseNav];
    
    self.tabBar.tintColor = [UIColor redColor];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
