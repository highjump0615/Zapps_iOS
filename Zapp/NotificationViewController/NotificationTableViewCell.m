//
//  NotificationTableViewCell.m
//  Zapp
//
//  Created by highjump on 14-7-23.
//  Copyright (c) 2014年 Tian. All rights reserved.
//

#import "NotificationTableViewCell.h"
#import "NotificationViewController.h"

@interface NotificationTableViewCell() <AVAudioPlayerDelegate>
{
    NotificationData *mNotifyData;
    NSString *mObjectId;
    NSMutableData *mAudioData;
    AVAudioPlayer *mPlayer;
    BOOL mbPlaying;
}

@end

@implementation NotificationTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)fillContent:(NotificationData *)data
{
    mNotifyData = data;
    mbPlaying = NO;
    
    [self.mButUser setImageEdgeInsets:UIEdgeInsetsMake(5, 5, 5, 5)];
    [self.mButUser.imageView.layer setMasksToBounds:YES];
    [self.mButUser.imageView.layer setCornerRadius:20];
    
    [self.mButUser setImage:[UIImage imageNamed:@"profile_photo_default.png"] forState:UIControlStateNormal];
    
    [mNotifyData.user fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error)
    {
        PFFile *fileImgPhoto = nil;
        if (mNotifyData.user[@"photothumb"])
        {
            fileImgPhoto = (PFFile *)mNotifyData.user[@"photothumb"];
        }
        else if (mNotifyData.user[@"photo"])
        {
            fileImgPhoto = (PFFile *)mNotifyData.user[@"photo"];
        }

        if (fileImgPhoto)
        {
            PFImageView *imageView = [[PFImageView alloc] init];
            imageView.file = fileImgPhoto;
            [imageView loadInBackground:^(UIImage *image, NSError *error) {
                [self.mButUser setImage:image forState:UIControlStateNormal];
            }];
        }
    }];
    
    // attributed text
    UIFont *helveticaBoldFont = [UIFont fontWithName:@"HelveticaNeue-Bold" size:13];
    
    NSString *strText;
    if (mNotifyData.notificationType == 0)   // like
    {
        strText = [NSString stringWithFormat:@"%@ liked your zapp", mNotifyData.strUsername];
    }
    else
    {
        strText = [NSString stringWithFormat:@"%@ commented your zapp", mNotifyData.strUsername];
    }
    
    NSMutableAttributedString *strAttributedText = [[NSMutableAttributedString alloc] initWithString:strText];
    [strAttributedText addAttribute:NSFontAttributeName
                              value:helveticaBoldFont
                              range:NSMakeRange(0, mNotifyData.strUsername.length)];
    
    [self.mLblText setAttributedText:strAttributedText];
    
    if (mNotifyData.type == 0)   // alert
    {
        [self.mButPlay setImage:[UIImage imageNamed:@"alert_play_but.png"] forState:UIControlStateNormal];
    }
    else
    {
        [self.mButPlay setImage:[UIImage imageNamed:@"fun_play_but.png"] forState:UIControlStateNormal];
    }
    [self.mButPlay setImageEdgeInsets:UIEdgeInsetsMake(10, 10, 10, 10)];

    // set up audio
    if (![mObjectId isEqualToString:mNotifyData.object.objectId])
    {
        // load zapp data
        [self.mButPlay setEnabled:NO];
        
        NSString *strZappUrl = mNotifyData.strAudioFile;
        NSURL *urlZapp = [NSURL URLWithString:strZappUrl];
        NSURLRequest *request = [NSURLRequest requestWithURL:urlZapp];
        
        [NSURLConnection connectionWithRequest:request delegate:self];
        
        mAudioData = [[NSMutableData alloc] init];
        mObjectId = mNotifyData.object.objectId;
    }
}

- (IBAction)onPlay:(id)sender
{
    CommonUtils *utils = [CommonUtils sharedObject];
    
    if (utils.mCurrentPlayer)
    {
        if (utils.mCurrentPlayer != mPlayer)
        {
            return;
        }
    }
    
    if (mbPlaying)
    {
        [mPlayer pause];
        [self stopPlaying];
    }
    else
    {
        if (mNotifyData.type == 0)   // alert
        {
            [self.mButPlay setImage:[UIImage imageNamed:@"alert_pause_but.png"] forState:UIControlStateNormal];
        }
        else if (mNotifyData.type == 1) // fun
        {
            [self.mButPlay setImage:[UIImage imageNamed:@"fun_pause_but.png"] forState:UIControlStateNormal];
        }
        
        [mPlayer play];
        
        utils.mCurrentPlayer = mPlayer;
        
        mbPlaying = YES;
    }

}

- (void)stopPlaying
{
    mbPlaying = NO;
    
    if (mNotifyData.type == 0)   // alert
    {
        [self.mButPlay setImage:[UIImage imageNamed:@"alert_play_but.png"] forState:UIControlStateNormal];
    }
    else
    {
        [self.mButPlay setImage:[UIImage imageNamed:@"fun_play_but.png"] forState:UIControlStateNormal];
    }

    
    if ([mPlayer isPlaying])
    {
        [mPlayer stop];
    }
    
    CommonUtils *utils = [CommonUtils sharedObject];
    utils.mCurrentPlayer = nil;
}


#pragma mark - NSURLConnectionDelegate
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [mAudioData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response
{
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    // init player
    NSError *playerError;
    mPlayer = [[AVAudioPlayer alloc] initWithData:mAudioData error:&playerError];
    mPlayer.volume = 5.0;
    if (!mPlayer)
    {
        NSLog(@"Error creating player: %@", [playerError description]);
        return;
    }
    mPlayer.delegate = self;
    
    [mPlayer prepareToPlay];
    [self.mButPlay setEnabled:YES];
}

#pragma mark - AVAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [self stopPlaying];
}

@end
