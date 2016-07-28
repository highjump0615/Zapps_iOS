//
//  HomeFeedCell.m
//  Zapp
//
//  Created by highjump on 14-7-10.
//  Copyright (c) 2014年 Tian. All rights reserved.
//

#import "HomeFeedCell.h"

#define screenWidth() (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation) ? [[UIScreen mainScreen] bounds].size.width : [[UIScreen mainScreen] bounds].size.height)

@implementation HomeFeedCell

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

- (void)stopPlaying
{
    if ([mPlayer isPlaying])
    {
        [mPlayer stop];
        [self.mImgWave.layer removeAllAnimations];
    }
    
    [self updateButtonImage];

    CommonUtils *utils = [CommonUtils sharedObject];
    utils.mCurrentPlayer = nil;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)updateButtonImage
{
    if ([mPlayer isPlaying])
    {
        if (self.mZappData.type == 0)   // alert
        {
            [self.mButPlay setImage:[UIImage imageNamed:@"alert_pause_but.png"] forState:UIControlStateNormal];
            [self.mImgWave setImage:[UIImage imageNamed:@"alert_play_wave.png"]];
        }
        else if (self.mZappData.type == 1) // fun
        {
            [self.mButPlay setImage:[UIImage imageNamed:@"fun_pause_but.png"] forState:UIControlStateNormal];
            [self.mImgWave setImage:[UIImage imageNamed:@"fun_play_wave.png"]];
        }
        
        [self.mLblContent setHidden:YES];
        [self.mViewWave setHidden:NO];
        
        [self startWaveAnimating];
    }
    else
    {
        if (self.mZappData.type == 0)   // alert
        {
            [self.mButPlay setImage:[UIImage imageNamed:@"alert_play_but.png"] forState:UIControlStateNormal];
        }
        else if (self.mZappData.type == 1) // fun
        {
            [self.mButPlay setImage:[UIImage imageNamed:@"fun_play_but.png"] forState:UIControlStateNormal];
        }
        
        [self.mLblContent setHidden:NO];
        [self.mViewWave setHidden:YES];
    }
    
    [self.mButPlay setImageEdgeInsets:UIEdgeInsetsMake(3, 3, 3, 3)];
}

- (void)fillContent:(ZappData *)data
{
    self.mZappData = data;
    
    [self.mLblContent setText:data.strDescription];
 
    // set the user
    [self.mButUser setImageEdgeInsets:UIEdgeInsetsMake(5, 5, 5, 5)];
    [self.mButUser.imageView.layer setMasksToBounds:YES];
    [self.mButUser.imageView.layer setCornerRadius:17.5];
    
    // username label
    [self.mLblUsername setText:self.mZappData.strUsername];

//    NSLog(@"current: %@, zapp: %@", mZappId, self.mZappData.strId);
    if (![mZappId isEqualToString:self.mZappData.strId])
    {
        [self swipeMenu];
        
        // user photo
        [self.mButUser setImage:[UIImage imageNamed:@"profile_photo_default.png"] forState:UIControlStateNormal];
        
        PFUser *userInfo = data.user;
        [userInfo fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error)
         {
             PFFile *fileImgPhoto = nil;
             if (userInfo[@"photothumb"])
             {
                 fileImgPhoto = (PFFile *)userInfo[@"photothumb"];
             }
             else if (userInfo[@"photo"])
             {
                 fileImgPhoto = (PFFile *)userInfo[@"photo"];
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

        // load zapp data
        [self.mButPlay setEnabled:NO];

        NSString *strZappUrl = self.mZappData.zappFile.url;
        NSURL *urlZapp = [NSURL URLWithString:strZappUrl];
        NSURLRequest *request = [NSURLRequest requestWithURL:urlZapp];
        
        [NSURLConnection connectionWithRequest:request delegate:self];
        
        mAudioData = [[NSMutableData alloc] init];
        mZappId = self.mZappData.strId;
        
        [mPlayer stop];
        mPlayer = nil;
        
        [self updateButtonImage];

    }
    
    
    // distance
    CommonUtils *utils = [CommonUtils sharedObject];
    
    CLLocationCoordinate2D currentCoordinate = utils.mCurrentLocation.coordinate;
	PFGeoPoint *currentPoint = [PFGeoPoint geoPointWithLatitude:currentCoordinate.latitude longitude:currentCoordinate.longitude];
    PFGeoPoint *zappPoint = (PFGeoPoint *)self.mZappData.object[@"location"];
    
    double distanceDouble = [currentPoint distanceInKilometersTo:zappPoint];
    [self.mLblDistance setText:[NSString stringWithFormat:@"%.1f Km", distanceDouble]];
    
    // time
    self.mLblTime.text = [CommonUtils getTimeString:data.date];
    
    // play count
    self.mLblPlayCount.text = [NSString stringWithFormat:@"%d", self.mZappData.nPlayCount];
    
    // like count
    self.mLblLikeCount.text = [NSString stringWithFormat:@"%d", self.mZappData.nLikeCount];
    
    // setlike
    self.mLblLikeCount.text = [NSString stringWithFormat:@"%d", data.nLikeCount];
    
    if (data.bLiked > 0)    // liked
    {
        [self.mButLike setImage:[UIImage imageNamed:@"zapp_liked_but.png"] forState:UIControlStateNormal];
        [self.mButLike setEnabled:YES];
    }
    else if (data.bLiked == 0)  // unliked
    {
        [self.mButLike setImage:[UIImage imageNamed:@"zapp_unliked_but.png"] forState:UIControlStateNormal];
        [self.mButLike setEnabled:YES];
    }
    else    // undetermined
    {
//        [self.mButLike setImage:[UIImage imageNamed:@"zapp_unliked_but.png"] forState:UIControlStateNormal];
        [self.mButLike setEnabled:NO];
    }

    if (mImgLikeView)
    {
        [mImgLikeView setHidden:YES];
    }
    
    // set comments
    if (data.nCommentCount)
    {
        [self.mButComment setImage:[UIImage imageNamed:@"zapp_comment_but.png"] forState:UIControlStateNormal];
        [self.mLblCommentCount setHidden:NO];
        [self.mLblCommentCount setText:[NSString stringWithFormat:@"%d", data.nCommentCount]];
    }
    else
    {
        [self.mButComment setImage:[UIImage imageNamed:@"zapp_uncommented_but.png"] forState:UIControlStateNormal];
        [self.mLblCommentCount setHidden:YES];
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
    
    if ([mPlayer isPlaying])
    {
        [self stopPlaying];
    }
    else
    {
        [mPlayer play];
        
        utils.mCurrentPlayer = mPlayer;
        
        self.mZappData.nPlayCount++;
        self.mLblPlayCount.text = [NSString stringWithFormat:@"%d", self.mZappData.nPlayCount];
        self.mZappData.object[@"playcount"] = [NSNumber numberWithInteger:self.mZappData.nPlayCount];
        [self.mZappData.object saveInBackground];
    }
    
    [self updateButtonImage];
}

- (void)startWaveAnimating
{
//    if ([self.mImgWave.layer.animationKeys count] > 0)
//    {
//        return;
//    }
    
    //
    // animate wave
    //
    //create an animation to follow a circular path
    CAKeyframeAnimation *pathAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    //interpolate the movement to be more smooth
    pathAnimation.calculationMode = kCAAnimationPaced;
    //apply transformation at the end of animation (not really needed since it runs forever)
    pathAnimation.fillMode = kCAFillModeForwards;
    pathAnimation.removedOnCompletion = NO;
    //run forever
    pathAnimation.repeatCount = INFINITY;
    //no ease in/out to have the same speed along the path
    pathAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    pathAnimation.duration = 2.0;
    
    //The circle to follow will be inside the circleContainer frame.
    //it should be a frame around the center of your view to animate.
    //do not make it to large, a width/height of 3-4 will be enough.
    CGMutablePathRef curvedPath = CGPathCreateMutable();
    
    CGPathMoveToPoint(curvedPath, NULL, self.mImgWave.frame.origin.x, self.mImgWave.frame.size.height / 2);
    CGPathAddLineToPoint(curvedPath, NULL, 0, self.mImgWave.frame.size.height / 2);
    
    CGPathMoveToPoint(curvedPath, NULL, self.mImgWave.frame.size.width / 2, self.mImgWave.frame.size.height / 2);
    CGPathAddLineToPoint(curvedPath, NULL, self.mImgWave.frame.origin.x, self.mImgWave.frame.size.height / 2);

    
    //add the path to the animation
    pathAnimation.path = curvedPath;
    //release path
//    CGPathRelease(curvedPath);
    
    //add animation to the view's layer
    [self.mImgWave.layer addAnimation:pathAnimation forKey:@"myCircleAnimation"];

//    [UIView animateKeyframesWithDuration:2.0
//                                   delay:0
//                                 options:UIViewKeyframeAnimationOptionRepeat|UIViewAnimationOptionCurveLinear
//                              animations:^{
//                                  CGRect rt = self.mImgWave.frame;
//                                  rt.origin.x -= self.mImgWave.frame.size.width / 2;
//                                  self.mImgWave.frame = rt;
//                              }
//                              completion:^(BOOL finished) {
//                                  CGRect rt = self.mImgWave.frame;
//                                  rt.origin.x += self.mImgWave.frame.size.width / 2;
//                                  self.mImgWave.frame = rt;
//                              }];

}

- (IBAction)onLike:(id)sender
{
    if (!self.mZappData.bLiked)
    {
        PFUser *currentUser = [PFUser currentUser];
        
        PFObject *like = [PFObject objectWithClassName:@"Likes"];
        like[@"zapp"] = self.mZappData.object;
        like[@"user"] = currentUser;
        like[@"username"] = [CommonUtils getUsernameToShow:[PFUser currentUser]];
        like[@"targetuser"] = self.mZappData.user;
        like[@"type"] = @(self.mZappData.type);
        like[@"zappfile"] = self.mZappData.zappFile.url;
        
        [like saveInBackground];
        
        self.mZappData.nLikeCount++;
    
        [self.mButLike setImage:[UIImage imageNamed:@"zapp_liked_but.png"] forState:UIControlStateNormal];
        self.mZappData.bLiked = YES;
        
        // like animation
        CABasicAnimation *pulseAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
        [pulseAnimation setDuration:0.2];
        [pulseAnimation setRepeatCount:3];
        
        // The built-in ease in/ ease out timing function is used to make the animation look smooth as the layer
        // animates between the two scaling transformations.
        [pulseAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
        
        // Scale the layer to half the size
        CATransform3D transform = CATransform3DMakeScale(1.6, 1.6, 1.0);
        
        // Tell CA to interpolate to this transformation matrix
        [pulseAnimation setToValue:[NSValue valueWithCATransform3D:CATransform3DIdentity]];
        [pulseAnimation setToValue:[NSValue valueWithCATransform3D:transform]];
        
        // Tells CA to reverse the animation (e.g. animate back to the layer's transform)
        [pulseAnimation setAutoreverses:YES];
        
        // Finally... add the explicit animation to the layer... the animation automatically starts.
        [self.mButLike.layer addAnimation:pulseAnimation forKey:@"BTSPulseAnimation"];

        
        //
        // send notification to liked user
        //
        PFQuery *query = [PFInstallation query];
        [query whereKey:@"user" equalTo:self.mZappData.user];
        
        // Send the notification.
        PFPush *push = [[PFPush alloc] init];
        [push setQuery:query];
        
        NSString *strMessage;
        strMessage = [NSString stringWithFormat:@"%@ liked your zapp", [CommonUtils getUsernameToShow:currentUser]];
        
        NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
                              strMessage, @"alert",
                              @"like", @"notifyType",
                              self.mZappData.object.objectId, @"notifyZapp",
                              @"Increment", @"badge",
                              @"cheering.caf", @"sound",
                              nil];
        [push setData:data];
        
        [push sendPushInBackground];
    }
    else
    {
        PFQuery *query = [PFQuery queryWithClassName:@"Likes"];
        [query whereKey:@"zapp" equalTo:self.mZappData.object];
        [query whereKey:@"user" equalTo:[PFUser currentUser]];
        [query findObjectsInBackgroundWithBlock:^(NSArray *likeobjects, NSError *error)
        {
            if (!error)
            {
                PFObject *object = [likeobjects objectAtIndex:0];
                [object deleteInBackground];
            }
            else {
                // Log details of the failure
                NSLog(@"Error: %@ %@", error, [error userInfo]);
            }
        }];
        
        [self.mButLike setImage:[UIImage imageNamed:@"zapp_unliked_but.png"] forState:UIControlStateNormal];
        self.mZappData.nLikeCount--;
        self.mZappData.bLiked = NO;

        
        if (!mImgLikeView)
        {
            mImgLikeView = [[UIImageView alloc] init];
            [self.mViewInfo addSubview:mImgLikeView];
        }

        [mImgLikeView setImage:[UIImage imageNamed:@"zapp_liked_but.png"]];
        [mImgLikeView setFrame:CGRectMake(self.mButLike.frame.origin.x + (35-20) / 2,
                                          self.mButLike.frame.origin.y + (35-18) / 2,
                                          20,
                                          18)];
        [mImgLikeView setHidden:NO];
        [mImgLikeView.layer setOpacity:1.0];

        // unlike animation
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        animation.duration = 0.5;
        animation.fromValue = [NSNumber numberWithFloat:1.0f];
        animation.toValue = [NSNumber numberWithFloat:0.0f];
        animation.removedOnCompletion = NO;
        animation.fillMode = kCAFillModeBoth;
        animation.additive = NO;
        [mImgLikeView.layer addAnimation:animation forKey:@"opacityOUT"];
        
        animation = [CABasicAnimation animationWithKeyPath:@"position.y"];
        animation.duration = 0.5;
        
        CGFloat halfBoxHeight = self.mButLike.frame.origin.y + self.mButLike.frame.size.height / 2;
        animation.fromValue = [NSNumber numberWithDouble:halfBoxHeight];
        animation.toValue = [NSNumber numberWithDouble:halfBoxHeight + 40.0];
        [mImgLikeView.layer addAnimation:animation forKey:@"downAnimation"];

    }
    
    [self.mLblLikeCount setText:[NSString stringWithFormat:@"%d", self.mZappData.nLikeCount]];
    
    PFObject *zappObj = self.mZappData.object;
    zappObj[@"likecount"] = [NSNumber numberWithInt:self.mZappData.nLikeCount];
    [zappObj saveInBackground];

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
