//
//  CommentViewController.h
//  Zapp
//
//  Created by highjump on 14-7-12.
//  Copyright (c) 2014年 Tian. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CommonUtils.h"

@protocol UpdateLikeCommentDelegate <NSObject>

- (void)updateZappInfo:(ZappData *)data;

@end



@interface CommentViewController : UIViewController

@property (strong) ZappData *mZappData;
@property (strong) id <UpdateLikeCommentDelegate> delegate;

@end
