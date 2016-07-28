//
//  CommentCell.m
//  Zapp
//
//  Created by highjump on 14-7-12.
//  Copyright (c) 2014年 Tian. All rights reserved.
//

#import "CommentCell.h"

@implementation CommentCell

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

- (void)fillContent:(CommentData *)data
{
    self.mCommentData = data;
    
    [self updateButtonImage];
    
    [self.mButUser setImageEdgeInsets:UIEdgeInsetsMake(5, 5, 5, 5)];
    [self.mButUser.imageView.layer setMasksToBounds:YES];
    [self.mButUser.imageView.layer setCornerRadius:20];
    
    [self.mLblUsername setText:data.strUsername];
    [self.mLblContent setText:data.strContent];
    
    if (![mCommentId isEqualToString:data.strId])
    {
        // user photo
        [self.mButUser setImage:[UIImage imageNamed:@"profile_photo_default.png"] forState:UIControlStateNormal];
        
        [data.user fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error)
         {
             if (!error)
             {
                 PFFile *photoFile;
                 if (data.user[@"photothumb"])
                 {
                     photoFile = data.user[@"photothumb"];
                 }
                 else
                 {
                     photoFile = data.user[@"photo"];
                 }
                 
                 if (photoFile)
                 {
                     PFImageView *imageView = [[PFImageView alloc] init];
                     imageView.file = photoFile;
                     [imageView loadInBackground:^(UIImage *image, NSError *error) {
                         [self.mButUser setImage:image forState:UIControlStateNormal];
                     }];
                 }
             }
         }];
    
        // load zapp data
        [self.mButPlay setEnabled:NO];
        
        if (data.voiceFile)
        {
            [self.mButPlay setHidden:NO];
            
            NSString *strVoice = data.voiceFile.url;
            NSURL *urlVoice = [NSURL URLWithString:strVoice];
            NSURLRequest *request = [NSURLRequest requestWithURL:urlVoice];
            
            [NSURLConnection connectionWithRequest:request delegate:self];
            
            mAudioData = [[NSMutableData alloc] init];
            mCommentId = data.strId;
        }
        else
        {
            mAudioData = nil;
            [self.mButPlay setHidden:YES];
        }
    }
}

- (void)updateButtonImage
{
    if ([mPlayer isPlaying])
    {
        if (self.mCommentData.type == 0)   // alert
        {
            [self.mButPlay setImage:[UIImage imageNamed:@"alert_pause_but.png"] forState:UIControlStateNormal];
        }
        else if (self.mCommentData.type == 1) // fun
        {
            [self.mButPlay setImage:[UIImage imageNamed:@"fun_pause_but.png"] forState:UIControlStateNormal];
        }
    }
    else
    {
        if (self.mCommentData.type == 0)   // alert
        {
            [self.mButPlay setImage:[UIImage imageNamed:@"alert_play_but.png"] forState:UIControlStateNormal];
        }
        else if (self.mCommentData.type == 1) // fun
        {
            [self.mButPlay setImage:[UIImage imageNamed:@"fun_play_but.png"] forState:UIControlStateNormal];
        }
    }
    
    [self.mButPlay setImageEdgeInsets:UIEdgeInsetsMake(8, 8, 8, 8)];
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
    
    if ([mPlayer isPlaying])
    {
        [mPlayer pause];
        [self stopPlaying];
    }
    else
    {
        [mPlayer play];
        
        utils.mCurrentPlayer = mPlayer;
    }
    
    [self updateButtonImage];
}


- (void)stopPlaying
{
    if ([mPlayer isPlaying])
    {
        [mPlayer stop];
    }
    
    [self updateButtonImage];
    
    CommonUtils *utils = [CommonUtils sharedObject];
    utils.mCurrentPlayer = nil;
}

#pragma mark - AVAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [self stopPlaying];
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


@end
