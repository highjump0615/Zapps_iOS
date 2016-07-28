//
//  CommonUtils.m
//  Zapp
//
//  Created by highjump on 14-7-11.
//  Copyright (c) 2014年 Tian. All rights reserved.
//

#import "CommonUtils.h"
#import "MBProgressHUD.h"
#import <MessageUI/MFMailComposeViewController.h>
#import "lame.h"

#import <Twitter/Twitter.h>

@implementation CommentData

- (CommentData *)initWithData:(PFObject *)commentObject
{
    self.strId = commentObject.objectId;
    self.strUsername = commentObject[@"username"];
    self.strContent = commentObject[@"content"];
    self.type = [commentObject[@"type"] intValue];
    self.date = [NSDate date];
    self.user = commentObject[@"user"];
    self.object = commentObject;
    self.voiceFile = commentObject[@"voice"];
    
    return self;
}

@end


@implementation NotificationData

- (NotificationData *)initWithData:(PFObject *)notificationObject
{
    self.user = notificationObject[@"user"];
    self.strUsername = notificationObject[@"username"];
    self.type = [notificationObject[@"type"] intValue];
    self.date = notificationObject.updatedAt;
    self.zapp = notificationObject[@"zapp"];
    self.strAudioFile = notificationObject[@"zappfile"];
    self.object = notificationObject;

    return self;
}

@end


@implementation ZappData

- (ZappData *)initWithZapp:(PFObject *)zappObject
{
    [self fillData:zappObject];
    
    return self;
}

- (void)fillData:(PFObject *)zappObject
{
    self.strId = zappObject.objectId;
    self.strUsername = zappObject[@"username"];
    self.type = [zappObject[@"type"] intValue];
    self.strDescription = zappObject[@"description"];
    self.zappFile = (PFFile *)zappObject[@"zapp"];
    self.date = zappObject.createdAt;
    self.user = zappObject[@"user"];
    self.object = zappObject;
    self.bLiked = -1;
    self.nLikeCount = [zappObject[@"likecount"] intValue];
    self.nCommentCount = [zappObject[@"commentcount"] intValue];
    self.nPlayCount = [zappObject[@"playcount"] intValue];
}

@end


@implementation CommonUtils


+ (id)sharedObject {
	static CommonUtils* utils = nil;
	if(utils == nil) {
		utils = [[CommonUtils alloc] init];
	}
	return utils;
}

+ (NSString *)getUsernameToShow:(PFUser *)user {
    
    NSString *strUsername = user[@"fullname"];
    
    if (strUsername && strUsername.length > 0) {
        return strUsername;
    }
    else {
        return user.username;
    }
}

+ (NSString *)getTimeString:(NSDate *)date {
    
    NSString *strTime = @"";
    
    NSTimeInterval time = -[date timeIntervalSinceNow];
    int min = (int)time / 60;
    int hour = min / 60;
    int day = hour / 24;
    int month = day / 30;
    int year = month / 12;
    
    if(min < 60) {
        strTime = [NSString stringWithFormat:@"%d min", min];
    }
    else if(min >= 60 && min < 60 * 24) {
        if(hour < 24) {
            strTime = [NSString stringWithFormat:@"%d hour", hour];
        }
    }
    else if (day < 31) {
        strTime = [NSString stringWithFormat:@"%d day", day];
    }
    else if (month < 12) {
        strTime = [NSString stringWithFormat:@"%d month", month];
    }
    else {
        strTime = [NSString stringWithFormat:@"%d year", year];
    }
    
    return strTime;
}

+ (int)getHeight:(NSString *)text fontsize:(int)nFontSize width:(int)nWidth height:(int)nHeight
{
    UIFont *helveticaFont = [UIFont fontWithName:@"HelveticaNeue" size:nFontSize];
    CGSize maximumLabelSize = CGSizeMake(nWidth, nHeight);
    
    //            CGRect textRect = [blog.strContent  boundingRectWithSize:maximumLabelSize   options:NSStringDrawingUsesLineFragmentOrigin  attributes:@{NSFontAttributeName:avenirnextFont} context:nil];
    
    UILabel *gettingSizeLabel = [[UILabel alloc] init];
    gettingSizeLabel.font = helveticaFont;
    gettingSizeLabel.text = text;
    gettingSizeLabel.numberOfLines = 0;
    
    CGSize expectedSize = [gettingSizeLabel sizeThatFits:maximumLabelSize];
    int nRes = expectedSize.height;
    
    if (nHeight > 0)
    {
        nRes = MAX(expectedSize.height, nHeight);
    }
    
    return nRes;
}


- (BOOL)convertToMp3:(NSURL *)source destination:(NSURL *)destination
{
    // convert audio to mp3
    NSFileManager* fileManager=[NSFileManager defaultManager];
    [fileManager removeItemAtPath:destination.path error:nil];
    
    @try {
        int read, write;
        
        FILE *pcm = fopen([source.path cStringUsingEncoding:1], "rb");  //source 被转换的音频文件位置
        fseek(pcm, 4*1024, SEEK_CUR);                                   //skip file header
        FILE *mp3 = fopen([destination.path cStringUsingEncoding:1], "wb");  //output 输出生成的Mp3文件位置
        
        const int PCM_SIZE = 8192;
        const int MP3_SIZE = 8192;
        short int pcm_buffer[PCM_SIZE*2];
        unsigned char mp3_buffer[MP3_SIZE];
        
        lame_t lame = lame_init();
        lame_set_in_samplerate(lame, 44100.0);
        lame_set_VBR(lame, vbr_default);
        lame_init_params(lame);
        
        do {
            read = fread(pcm_buffer, 2*sizeof(short int), PCM_SIZE, pcm);
            if (read == 0)
                write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
            else
                write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
            
            fwrite(mp3_buffer, write, 1, mp3);
            
        } while (read != 0);
        
        lame_close(lame);
        fclose(mp3);
        fclose(pcm);
    }
    @catch (NSException *exception) {
        NSLog(@"%@",[exception description]);
        
        return NO;
    }
    @finally {
    }
    
    return YES;
}

- (void)loginWithFacebook:(UIViewController *)viewController button:(UIButton *)button segue:(NSString *)segueString
{
    [button setEnabled:NO];
    
    NSArray *permissionsArray = @[@"user_about_me", @"email", @"publish_actions", @"publish_stream", @"user_location"];
    
    [PFFacebookUtils logInWithPermissions:permissionsArray block:^(PFUser *user, NSError *error) {
        
        CommonUtils* utils = [CommonUtils sharedObject];
        
        [MBProgressHUD hideHUDForView:viewController.view animated:YES];
        [button setEnabled:YES];
        
        if (!user) {
            NSLog(@"Uh oh. The user cancelled the Facebook login.");
        }
        else if (user.isNew) {
            NSLog(@"User signed up and logged in through Facebook!");
            
            // Create request for user's Facebook data
            FBRequest *request = [FBRequest requestForMe];
            
            // Send request to Facebook
            [request startWithCompletionHandler:^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *userData, NSError *error) {
                
                [MBProgressHUD hideHUDForView:viewController.view animated:YES];
                
                //                for(id key in user)
                //                {
                //                    NSLog(@"key=%@ value=%@", key, [user objectForKey:key]);
                //                }
                
                
                PFUser *currentUser = [PFUser currentUser];
                
                if (!error) {
                    
                    // check and see if a user already exists for this email
                    PFQuery *query = [PFUser query];
                    [query whereKey:@"email" equalTo:userData[@"email"]];
                    [query countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
                        if(number > 0) {
                            
                            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Alert"
                                                                            message:[NSString stringWithFormat:@"%@ is already existing", userData[@"email"]]
                                                                           delegate:nil
                                                                  cancelButtonTitle:@"OK"
                                                                  otherButtonTitles:nil];
                            [alert show];
                            
                            // delete the user that was created as part of Parse's Facebook login
                            [currentUser deleteInBackground];
                            [PFUser logOut];
                            
                            // put the user logged out notification on the wire
                            [[FBSession activeSession] closeAndClearTokenInformation];
                            
                        }
                        else {
                            
                            for(id key in userData)
                            {
                                NSLog(@"key=%@ value=%@", key, [userData objectForKey:key]);
                            }
                            
                            if (userData[@"username"]) {
                                currentUser.username = userData[@"username"];
                            }
                            
                            if (userData[@"name"]) {
                                currentUser[@"fullname"] = userData[@"name"];
                            }
                            
//                            if (userData[@"location"]) {
//                                currentUser[@"location"] = userData[@"location"][@"name"];
//                            }
                            currentUser.email = userData[@"email"];
                            
                            NSString *facebookID = userData[@"id"];
                            NSURL *pictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1", facebookID]];
                            
                            NSData *data = [NSData dataWithContentsOfURL:pictureURL];
                            PFFile *photoFile = [PFFile fileWithData:data];
                            currentUser[@"photo"] = photoFile;
                            
                            currentUser[@"distanceFilter"] = [NSNumber numberWithBool:NO];
                            currentUser[@"distance"] = [NSNumber numberWithInteger:50];
                            
                            [currentUser saveInBackground];
                            
                            [utils gotoMain:viewController segue:segueString];
                        }
                    }];
                }
                else
                {
                    // delete the user that was created as part of Parse's Facebook login
                    [currentUser deleteInBackground];
                    //                            [PFUser logOut];
                    
                    // put the user logged out notification on the wire
                    [[FBSession activeSession] closeAndClearTokenInformation];
                }
                
            }];
            
            [MBProgressHUD showHUDAddedTo:viewController.view animated:YES];
            
        }
        else
        {
            NSLog(@"User logged in through Facebook!");
            
            if (user)
            {
                [utils gotoMain:viewController segue:segueString];
            }
        }
        
    }];
    
    [MBProgressHUD showHUDAddedTo:viewController.view animated:YES];
}

- (void)loginWithTwitter:(UIViewController *)viewController button:(UIButton *)button segue:(NSString *)segueString
{
    [button setEnabled:NO];
    
    [PFTwitterUtils logInWithBlock:^(PFUser *user, NSError *error) {
        
        CommonUtils* utils = [CommonUtils sharedObject];
        
        [MBProgressHUD hideHUDForView:viewController.view animated:YES];
        [button setEnabled:YES];
        
        if (!user) {
            NSLog(@"Uh oh. The user cancelled the Twitter login.");
            return;
        } else if (user.isNew) {
            NSLog(@"User signed up and logged in with Twitter!");
            
            PFUser *currentUser = [PFUser currentUser];
            currentUser.username = [[PFTwitterUtils twitter] screenName];
            
            // check and see if a user already exists for this email
            PFQuery *query = [PFUser query];
            [query whereKey:@"username" equalTo:currentUser.username];
            [query countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
                if(number > 0) {
                    
                    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Alert"
                                                                    message:[NSString stringWithFormat:@"%@ is already existing", currentUser.username]
                                                                   delegate:nil
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
                    [alert show];
                    
                    // delete the user that was created as part of Parse's Facebook login
                    [currentUser deleteInBackground];
                    //                    [PFUser logOut];
                }
                else {
                    NSURL *urlShow = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.twitter.com/1.1/users/show.json?screen_name=%@", currentUser.username]];
                    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:urlShow];
                    [[PFTwitterUtils twitter] signRequest:request];
                    NSURLResponse *response = nil;
                    NSData *data = [NSURLConnection sendSynchronousRequest:request
                                                         returningResponse:&response
                                                                     error:&error];
                    
                    if ( error == nil){
                        NSDictionary* result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
                        NSURL *pictureURL = [NSURL URLWithString:[result objectForKey:@"profile_image_url_https"]];
                        
                        NSData *data = [NSData dataWithContentsOfURL:pictureURL];
                        PFFile *photoFile = [PFFile fileWithData:data];
                        currentUser[@"photo"] = photoFile;
                        
                        NSString * names = [result objectForKey:@"name"];
                        [currentUser setObject:names forKey:@"fullname"];
                        
                        currentUser[@"distanceFilter"] = [NSNumber numberWithBool:NO];
                        currentUser[@"distance"] = [NSNumber numberWithInteger:50];
                        
                        [currentUser saveInBackground];
                        [utils gotoMain:viewController segue:segueString];
                    }
                }
                
                [MBProgressHUD hideHUDForView:viewController.view animated:YES];
            }];
            
            [MBProgressHUD showHUDAddedTo:viewController.view animated:YES];
        }
        else {
            NSLog(@"User logged in with Twitter!");
            
            if (user) {
                [utils gotoMain:viewController segue:segueString];
            }
            
        }
        
    }];
    
    [MBProgressHUD showHUDAddedTo:viewController.view animated:YES];
}

- (void)reportEmail:(UIViewController *)viewController {
    
    MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
    controller.mailComposeDelegate = viewController;
    [controller setSubject:@"Report"];
    
    NSArray *usersTo = [NSArray arrayWithObject:@"info@skilledapp.co"];
    [controller setToRecipients:usersTo];
    
    NSString* strMsg = [NSString stringWithFormat:@""];
    [controller setMessageBody:strMsg isHTML:NO];
    
    if (controller) {
        [viewController.navigationController presentViewController: controller animated: YES completion:^{
        }];
    }
}

- (void)gotoMain:(UIViewController *)displayView segue:(NSString *)segueString
{
    // Associate the device with a user
    PFInstallation *installation = [PFInstallation currentInstallation];
    installation[@"user"] = [PFUser currentUser];
    [installation saveInBackground];
    
    // get user info if Facebook or Twitter user
    //            BOOL isLinkedToFacebook = [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]];
    [displayView performSegueWithIdentifier:segueString sender:nil];
}


- (void)stopCurrentPlaying
{
    [self.mCurrentPlayer stop];
    self.mCurrentPlayer = nil;
}


#pragma mark - Image Processing

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize
{
    //UIGraphicsBeginImageContext(newSize);
    // In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
    // Pass 1.0 to force exact pixel size.
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

+ (UIImage *)imageWithImage: (UIImage*) sourceImage scaledToHeight: (float) i_height width:(float)i_width
{
    float oldHeight = sourceImage.size.height;
    float scaleFactor = i_height / oldHeight;
    
    float newWidth = sourceImage.size.width * scaleFactor;
    float newHeight = oldHeight * scaleFactor;
    
    UIGraphicsBeginImageContext(CGSizeMake(i_width, newHeight));
    [sourceImage drawInRect:CGRectMake(-(newWidth - i_width) / 2, 0, newWidth, newHeight)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (void)shareToFacebook:(UIViewController *)viewController text:(NSString *)strContent url:(NSString *)strUrl
{
    //  Create an instance of the Tweet Sheet
    SLComposeViewController *facebookSheet = [SLComposeViewController
                                              composeViewControllerForServiceType:
                                              SLServiceTypeFacebook];
    
    // Sets the completion handler.  Note that we don't know which thread the
    // block will be called on, so we need to ensure that any required UI
    // updates occur on the main queue
    facebookSheet.completionHandler = ^(SLComposeViewControllerResult result) {
        switch(result) {
                //  This means the user cancelled without sending the Tweet
            case SLComposeViewControllerResultCancelled:
                NSLog(@"SLComposeViewControllerResultCancelled");
                break;
                //  This means the user hit 'Send'
            case SLComposeViewControllerResultDone: {
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Success"
                                                                message:@"Successfully posted to Facebook"
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
                break;
            }
        }
    };
    
    //  Set the initial body of the Tweet
    [facebookSheet setInitialText:strContent];

    if (![facebookSheet addURL:[NSURL URLWithString:strUrl]])
    {
        NSLog(@"Unable to add the URL!");
    }
    
    //  Presents the Tweet Sheet to the user
    [viewController presentViewController:facebookSheet animated:NO completion:^{
        NSLog(@"Facebook posting has done.");
    }];
}

- (void)shareToTwitter:(UIViewController *)viewController text:(NSString *)strContent url:(NSString *)strUrl
{
    //  Create an instance of the Tweet Sheet
    SLComposeViewController *tweetSheet = [SLComposeViewController
                                           composeViewControllerForServiceType:
                                           SLServiceTypeTwitter];
    
    // Sets the completion handler.  Note that we don't know which thread the
    // block will be called on, so we need to ensure that any required UI
    // updates occur on the main queue
    tweetSheet.completionHandler = ^(SLComposeViewControllerResult result) {
        switch(result) {
                //  This means the user cancelled without sending the Tweet
            case SLComposeViewControllerResultCancelled:
                break;
                //  This means the user hit 'Send'
            case SLComposeViewControllerResultDone: {
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Success"
                                                                message:@"Successfully posted to Twitter"
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
                
                break;
            }
        }
    };
    
    //  Set the initial body of the Tweet
    [tweetSheet setInitialText:strContent];
    
    //  Add an URL to the Tweet.  You can add multiple URLs.
    if (![tweetSheet addURL:[NSURL URLWithString:strUrl]])
    {
        NSLog(@"Unable to add the URL!");
    }
    
    //  Presents the Tweet Sheet to the user
    [viewController presentViewController:tweetSheet animated:NO completion:^{
        NSLog(@"Tweet sheet has been presented.");
    }];

}


@end
