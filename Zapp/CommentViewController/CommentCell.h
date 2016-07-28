//
//  CommentCell.h
//  Zapp
//
//  Created by highjump on 14-7-12.
//  Copyright (c) 2014年 Tian. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SlideTableViewCell.h"
#import "CommonUtils.h"

@interface CommentCell : SlideTableViewCell <AVAudioPlayerDelegate>
{
    NSString *mCommentId;
    
    NSMutableData *mAudioData;
    AVAudioPlayer *mPlayer;
}

@property (weak, nonatomic) IBOutlet UIButton *mButUser;
@property (weak, nonatomic) IBOutlet UILabel *mLblUsername;
@property (weak, nonatomic) IBOutlet UILabel *mLblContent;
@property (weak, nonatomic) IBOutlet UIButton *mButPlay;

@property (strong) CommentData *mCommentData;

- (void)fillContent:(CommentData *)data;

@end
