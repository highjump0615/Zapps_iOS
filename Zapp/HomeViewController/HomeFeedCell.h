//
//  HomeFeedCell.h
//  Zapp
//
//  Created by highjump on 14-7-10.
//  Copyright (c) 2014年 Tian. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SlideTableViewCell.h"
#import "CommonUtils.h"

@interface HomeFeedCell : SlideTableViewCell <AVAudioPlayerDelegate>
{
    NSString *mZappId;
    
    NSMutableData *mAudioData;
    AVAudioPlayer *mPlayer;
    
    UIImageView *mImgLikeView;
}

@property (weak, nonatomic) IBOutlet UIButton *mButPlay;
@property (weak, nonatomic) IBOutlet UILabel *mLblContent;

@property (weak, nonatomic) IBOutlet UIView *mViewWave;
@property (weak, nonatomic) IBOutlet UIImageView *mImgWave;

@property (weak, nonatomic) IBOutlet UIView *mViewInfo;
@property (weak, nonatomic) IBOutlet UIButton *mButLike;
@property (weak, nonatomic) IBOutlet UIButton *mButComment;
@property (weak, nonatomic) IBOutlet UILabel *mLblCommentCount;

@property (weak, nonatomic) IBOutlet UIButton *mButUser;
@property (weak, nonatomic) IBOutlet UILabel *mLblUsername;

@property (weak, nonatomic) IBOutlet UILabel *mLblDistance;
@property (weak, nonatomic) IBOutlet UILabel *mLblTime;
@property (weak, nonatomic) IBOutlet UILabel *mLblPlayCount;
@property (weak, nonatomic) IBOutlet UILabel *mLblLikeCount;

@property (strong) ZappData *mZappData;


- (void)fillContent:(ZappData *)data;
- (void)stopPlaying;

@end
