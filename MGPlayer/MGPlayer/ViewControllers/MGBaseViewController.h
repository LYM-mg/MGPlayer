//
//  MGBaseViewController.h
//  MGPlayer
//
//  Created by ming on 16/6/3.
//  Copyright © 2016年 ming. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MGBaseViewController : UIViewController
@property (nonatomic,retain) MBProgressHUD* hud;
- (void)addHud;
- (void)addHudWithMessage:(NSString*)message;
- (void)removeHud;
@end
