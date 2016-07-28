//
//  ProfileSettingViewController.h
//  Zapp
//
//  Created by highjump on 14-7-11.
//  Copyright (c) 2014年 Tian. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol BackToRootDelegate <NSObject>

- (void)backToRootView;
- (void)updateUserInfo;

@end

@interface ProfileSettingViewController : UIViewController

@property (strong) id <BackToRootDelegate> delegate;

@end
