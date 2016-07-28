//
//  NotificationTableViewCell.h
//  Zapp
//
//  Created by highjump on 14-7-23.
//  Copyright (c) 2014年 Tian. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CommonUtils.h"

@interface NotificationTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIButton *mButUser;
@property (weak, nonatomic) IBOutlet UILabel *mLblText;
@property (weak, nonatomic) IBOutlet UIButton *mButPlay;

- (void)fillContent:(NotificationData *)data;
- (void)stopPlaying;

@end
