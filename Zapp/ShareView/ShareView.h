//
//  ShareView.h
//  Zapp
//
//  Created by highjump on 14-7-29.
//  Copyright (c) 2014年 Tian. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol HideDelegate <NSObject>

- (void)hideShareView;

@end


@interface ShareView : UIView

@property (strong) id <HideDelegate> delegate;

- (void)showShadow;
- (void)setZappData:(id)data;

@end
