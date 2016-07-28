//
//  CommentViewController.m
//  Zapp
//
//  Created by highjump on 14-7-12.
//  Copyright (c) 2014年 Tian. All rights reserved.
//

#import "CommentViewController.h"
#import "HomeFeedCell.h"
#import "CommentCell.h"
#import "ProfileViewController.h"
#import "ShareView.h"

#import "MBProgressHUD.h"
#import <MessageUI/MFMailComposeViewController.h>

@interface CommentViewController () <UIGestureRecognizerDelegate, AVAudioPlayerDelegate, HideDelegate, MFMailComposeViewControllerDelegate>
{
    UITapGestureRecognizer * _tapGestureRecognizer;
    NSMutableArray *mCommentList;
    
    BOOL m_bReady;
    
    NSTimer *mRecordTimer;
    NSDate *mCurrentDate;
    
    AVAudioRecorder *mRecorder;
    AVAudioPlayer *mRecordPlayer;
    NSURL *mRecordedFile;
    NSURL *mRecordedFileMp3;
    
    int m_nCurCommentIndex;
    
    int m_nShareShowYPos;
    int m_nShareHideYPos;
    
    BOOL m_bRecording;
}

@property (weak, nonatomic) IBOutlet UIView *mViewText;
@property (weak, nonatomic) IBOutlet UIView *mViewRecording;
@property (weak, nonatomic) IBOutlet UILabel *mLblRecording;

@property (weak, nonatomic) IBOutlet UITableView *mTableView;
@property (weak, nonatomic) IBOutlet UITextField *mTxtComment;
@property (weak, nonatomic) IBOutlet UIButton *mButRecPlay;

@property (weak, nonatomic) IBOutlet UIButton *mButRecord;
@property (weak, nonatomic) IBOutlet UIButton *mButSend;

@property (weak, nonatomic) IBOutlet ShareView *mViewShare;
@property (weak, nonatomic) IBOutlet UIView *mViewPopupMask;

@end

@implementation CommentViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)updateTable
{
    if (m_bReady)
    {
        [self.mTableView reloadData];
    }
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (!self.mZappData.user)
    {
        m_bReady = NO;
        
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [self.mTableView setHidden:YES];
        
        [self.mZappData.object fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error)
        {
            [self.mZappData fillData:object];
            [self getLikeCommentInfo:self.mZappData];
            
            m_bReady = YES;
            [self.mButRecord setEnabled:YES];
                
            [self.mTableView setHidden:NO];
            [self updateTable];
            
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        }];
    }
    else
    {
        m_bReady = YES;
        [self.mButRecord setEnabled:YES];
    }
    
    self.mViewText.layer.borderColor = [UIColor colorWithRed:233/255.0 green:231/255.0 blue:227/255.0 alpha:1].CGColor;
    self.mViewText.layer.borderWidth = 1.0f;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillShow:)
												 name:UIKeyboardWillShowNotification
											   object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillHide:)
												 name:UIKeyboardWillHideNotification
											   object:nil];
    
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
    _tapGestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:_tapGestureRecognizer];

    mCommentList = [[NSMutableArray alloc] init];

    // get comment data
    PFQuery *query = [PFQuery queryWithClassName:@"Comments"];
    [query whereKey:@"zapp" equalTo:self.mZappData.object];
    [query orderByDescending:@"updatedAt"];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *commentobjects, NSError *error)
     {
         if (!error)
         {
             for (PFObject *object in commentobjects)
             {
                 CommentData *comment = [[CommentData alloc] initWithData:object];
                 [mCommentList addObject:comment];
             }

             [self updateTable];
         }
         else {
             // Log details of the failure
             NSLog(@"Error: %@ %@", error, [error userInfo]);
         }
     }];
    
    
    // set record area
    [self.mButSend setHidden:YES];
    [self.mViewRecording setHidden:YES];
    
    // initializing record
    mRecorder = nil;
    mRecordPlayer = nil;
    
    mRecordedFile = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingString:@"VoiceCommentFile.caf"]];
    mRecordedFileMp3 = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingString:@"VoiceCommentFile.mp3"]];
    ////////////////////
    
    [self.mButRecPlay setImageEdgeInsets:UIEdgeInsetsMake(6.5, 6.5, 6.5, 6.5)];
    
    // share view
    m_nShareHideYPos = self.view.frame.size.height + 3;
    m_nShareShowYPos = m_nShareHideYPos - self.mViewShare.frame.size.height;
    
    [self.mViewShare showShadow];
    self.mViewShare.delegate = self;
    
    [self.mViewShare setFrame:CGRectMake(0, m_nShareHideYPos, self.mViewShare.frame.size.width, self.mViewShare.frame.size.height)];
    
    m_bRecording = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    if (self.mZappData.user)
    {
        [self getLikeCommentInfo:self.mZappData];
        [self updateTable];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    CommonUtils *utils = [CommonUtils sharedObject];
    [utils stopCurrentPlaying];
}

- (void)getLikeCommentInfo:(ZappData *)zapp
{
    PFQuery *query = [PFQuery queryWithClassName:@"Likes"];
    [query whereKey:@"zapp" equalTo:zapp.object];
    [query whereKey:@"user" equalTo:[PFUser currentUser]];
    
    zapp.bLiked = -1;
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *likeobjects, NSError *error) {
        
        if (!error) {
            if (likeobjects.count > 0) {
                zapp.bLiked = 1;
            }
            else {
                zapp.bLiked = 0;
            }
            
            [self updateTable];
        }
        else {
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    }];
    
    [zapp.object fetchInBackgroundWithBlock:^(PFObject *object, NSError *error)
     {
         zapp.nLikeCount = [zapp.object[@"likecount"] intValue];
         zapp.nPlayCount = [zapp.object[@"playcount"] intValue];
         zapp.nCommentCount = [zapp.object[@"commentcount"] intValue];
         
         [self updateTable];
     }];
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([[segue identifier] isEqualToString:@"Comment2Profile"])
    {
        ProfileViewController *profileView = (ProfileViewController *)[segue destinationViewController];
        
        if (m_nCurCommentIndex >= 0)
        {
            CommentData *comment = [mCommentList objectAtIndex:m_nCurCommentIndex];
            profileView.mUser = comment.user;
        }
        else
        {
            profileView.mUser = self.mZappData.user;
        }
    }
}


- (IBAction)onDone:(id)sender {
//    [self dismissViewControllerAnimated:YES completion:nil];
    [[self navigationController] popViewControllerAnimated:YES];
}

- (void)tapped:(UIGestureRecognizer *)gestureRecognizer
{
    [self.view endEditing:YES];
}



#pragma mark - TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    int nCount;
    
    if (m_bReady)
    {
        nCount = (int)mCommentList.count + 1;
    }
    else
    {
        nCount = 0;
    }
    
    return nCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *tableCell;
    
    if (indexPath.row == 0)
    {
        HomeFeedCell *feedCell = (HomeFeedCell *)[tableView dequeueReusableCellWithIdentifier:@"CommentListZappCell"];
        feedCell.mnMode = 0;
        
        [feedCell fillContent:self.mZappData];
        
        [feedCell.mButUser addTarget:self action:@selector(onBtnZappUserPhoto:) forControlEvents:UIControlEventTouchUpInside];
        feedCell.mButUser.tag = indexPath.row;
        
        [feedCell.mButReport addTarget:self action:@selector(onListReport:) forControlEvents:UIControlEventTouchUpInside];

        [feedCell.mButShare addTarget:self action:@selector(onListShare:) forControlEvents:UIControlEventTouchUpInside];
        feedCell.mButShare.tag = -1;
        
        tableCell = feedCell;
    }
    else
    {
        CommentCell *commentCell = (CommentCell *)[tableView dequeueReusableCellWithIdentifier:@"CommentListCell"];
        [commentCell swipeMenu];
        
        CommentData *comment = [mCommentList objectAtIndex:indexPath.row - 1];
        [commentCell fillContent:comment];
        
        [commentCell.mButUser addTarget:self action:@selector(onBtnCommentUserPhoto:) forControlEvents:UIControlEventTouchUpInside];
        commentCell.mButUser.tag = indexPath.row - 1;
        
        [commentCell.mButReport addTarget:self action:@selector(onListReport:) forControlEvents:UIControlEventTouchUpInside];
        
        [commentCell.mButShare addTarget:self action:@selector(onListShare:) forControlEvents:UIControlEventTouchUpInside];
        commentCell.mButShare.tag = indexPath.row - 1;
        
        tableCell = commentCell;
    }
    
    return tableCell;
}

- (void)onBtnLike:(id)sender
{
//    if (self.delegate)
//    {
//        [self.delegate updateZappInfo:self.mZappData];
//    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    int nHeight = 55;
    
    if (indexPath.row == 0)
    {
        nHeight = [CommonUtils getHeight:self.mZappData.strDescription fontsize:13  width:241 height:0] + TEXT_FACTOR;
    }
    else
    {
        CommentData *comment = [mCommentList objectAtIndex:indexPath.row - 1];
        
        nHeight = [CommonUtils getHeight:comment.strContent fontsize:12 width:207 height:15] + 40;
    }
    
    return nHeight;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.view endEditing:YES];
}

- (void)onBtnZappUserPhoto:(id)sender
{
    m_nCurCommentIndex = -1;
    
    if ([self.mZappData.user.objectId isEqualToString:[PFUser currentUser].objectId])
    {
        return;
    }
    
    [self performSegueWithIdentifier:@"Comment2Profile" sender:nil];
}

- (void)onBtnCommentUserPhoto:(id)sender
{
    m_nCurCommentIndex = (int)((UIButton*)sender).tag;
    
    CommentData *comment = [mCommentList objectAtIndex:m_nCurCommentIndex];
    if ([comment.user.objectId isEqualToString:[PFUser currentUser].objectId])
    {
        return;
    }
    
    [self performSegueWithIdentifier:@"Comment2Profile" sender:nil];
}

- (void)onListReport:(id)sender
{
    CommonUtils *utils = [CommonUtils sharedObject];
    [utils reportEmail:self];
}

- (void)onListShare:(id)sender
{
    m_nCurCommentIndex = (int)((UIButton*)sender).tag;

    if (m_nCurCommentIndex >= 0)    // comment
    {
        CommentData *comment = [mCommentList objectAtIndex:m_nCurCommentIndex];
        [self.mViewShare setZappData:comment];
    }
    else
    {
        [self.mViewShare setZappData:self.mZappData];
    }
    
    if (self.mViewShare.frame.origin.y == m_nShareHideYPos)
    {
        [self.mViewPopupMask setHidden:NO];
        [UIView animateWithDuration:0.3
                         animations:^{
                             CGRect rt = self.mViewShare.frame;
                             rt.origin.y = m_nShareShowYPos;
                             self.mViewShare.frame = rt;
                             [self.mViewPopupMask setAlpha:0.3];
                         }completion:^(BOOL finished) {
                             //						 self.view.userInteractionEnabled = YES;
                         }];
    }
}

#pragma mark - HideShare Delegate
- (void)hideShareView
{
    if (self.mViewShare.frame.origin.y == m_nShareShowYPos) {
        [UIView animateWithDuration:0.3
                         animations:^{
                             CGRect rt = self.mViewShare.frame;
                             rt.origin.y = m_nShareHideYPos;
                             self.mViewShare.frame = rt;
                             [self.mViewPopupMask setAlpha:0];
                         }completion:^(BOOL finished) {
                             //						 self.view.userInteractionEnabled = YES;
                             [self.mViewPopupMask setHidden:YES];
                         }];
    }
}


- (void)animationView:(CGFloat)yPos {
    
    if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortrait)
    { //phone
        
        CGSize sz = [[UIScreen mainScreen] bounds].size;
        if(yPos == sz.height - self.view.frame.size.height)
            return;
//        self.view.userInteractionEnabled = NO;
        [UIView animateWithDuration:0.3
                         animations:^{
                             CGRect rt = self.view.frame;
                             rt.size.height = sz.height - yPos;
                             
                             //                             NSLog(@"animationview: %f", rt.size.height);
                             self.view.frame = rt;
                         }completion:^(BOOL finished) {
//                             self.view.userInteractionEnabled = YES;
                         }];
    }
}

#pragma mark - KeyBoard notifications
- (void)keyboardWillShow:(NSNotification*)notify
{
	CGRect rtKeyBoard = [(NSValue*)[notify.userInfo valueForKey:@"UIKeyboardFrameEndUserInfoKey"] CGRectValue];
    
    if ([UIApplication sharedApplication].statusBarOrientation != UIInterfaceOrientationPortrait) {
        [self animationView:rtKeyBoard.size.width];
    }
    else {
        [self animationView:rtKeyBoard.size.height];
    }
}

- (void)keyboardWillHide:(NSNotification*)notify
{
	[self animationView:0];
}

# pragma mark - Text filed
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    // record
//    if (self.mTxtComment.text.length > 0)
//    {
        [mRecordPlayer stop];
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        
        PFObject *commentObj = [PFObject objectWithClassName:@"Comments"];
        commentObj[@"zapp"] = self.mZappData.object;
        commentObj[@"user"] = [PFUser currentUser];
        commentObj[@"content"] = self.mTxtComment.text;
        commentObj[@"username"] = [CommonUtils getUsernameToShow:[PFUser currentUser]];
        commentObj[@"targetuser"] = self.mZappData.user;
        commentObj[@"type"] = @(self.mZappData.type);
        commentObj[@"content"] = self.mTxtComment.text;
        commentObj[@"zappfile"] = self.mZappData.zappFile.url;
        
        if (mRecordPlayer)
        {
            [hud setLabelText:@"Processing Audio Data..."];
            
            CommonUtils *utils = [CommonUtils sharedObject];
            if ([utils convertToMp3:mRecordedFile destination:mRecordedFileMp3] == NO)
            {
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                return NO;
            }

            // upload mp3 data
            NSData *zappData = [NSData dataWithContentsOfURL:mRecordedFileMp3];
            NSLog(@"mp3 length  :%lu", (unsigned long)zappData.length);
            commentObj[@"voice"] = [PFFile fileWithName:@"comment.mp3" data:zappData];
        }
        
        [hud setLabelText:@"Uploading Comment..."];
        
        [commentObj saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
        {
            CommentData *comment = [[CommentData alloc] initWithData:commentObj];
            [mCommentList insertObject:comment atIndex:0];
            
            self.mZappData.nCommentCount++;
            self.mZappData.object[@"commentcount"] = [NSNumber numberWithInt:self.mZappData.nCommentCount];
            [self.mZappData.object saveInBackground];
            
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            
            // restore comment input view
            mRecorder = nil;
            mRecordPlayer = nil;
            [self.mButRecPlay setHidden:YES];
            [self.mTxtComment setFrame:CGRectMake(0,
                                                  self.mTxtComment.frame.origin.y,
                                                  241,
                                                  self.mTxtComment.frame.size.height)];
            
            [self tapped:nil];
            
            self.mTxtComment.text = @"";
            [self.mTableView reloadData];
            
            [textField resignFirstResponder];

            //
            // send notification to commented user
            //
            PFQuery *query = [PFInstallation query];
            [query whereKey:@"user" equalTo:self.mZappData.user];
            
            // Send the notification.
            PFPush *push = [[PFPush alloc] init];
            [push setQuery:query];
            
            NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSString stringWithFormat:@"%@ commented you", [CommonUtils getUsernameToShow:[PFUser currentUser]]], @"alert",
                                  @"comment", @"notifyType",
                                  self.mZappData.object.objectId, @"notifyZapp",
                                  @"Increment", @"badge",
                                  @"cheering.caf", @"sound",
                                  nil];
            [push setData:data];
            
            [push sendPushInBackground];
            
        }];
        
        return YES;
//    }
//    else
//    {
//        return NO;
//    }
}


#pragma mark - Record Operation

- (void)stopRecording
{
    if (mRecordTimer)
    {
        [mRecordTimer invalidate];
        mRecordTimer = nil;
    }
    
    if (mRecorder)
    {
        [mRecorder stop];
        mRecorder = nil;
    }
}

- (void)updateRecordProgress:(NSTimer *)theTimer
{
    NSTimeInterval interval = 0;
    interval = [[NSDate date] timeIntervalSinceDate:mCurrentDate];
    int nElapsed = (int)interval;
    
    [self.mLblRecording setText:[NSString stringWithFormat:@"Recording... %ds", 10 - nElapsed]];
    
    if (interval >= 10.0)
    {
        [self onButRecord:self.mButRecord];
    }
}

- (IBAction)onButRecordDown:(id)sender
{
    [self.mTxtComment setHidden:YES];
    [self.mButRecPlay setHidden:YES];
    [self.mViewRecording setHidden:NO];
    
    [self stopRecording];
    
    mCurrentDate = [NSDate date];
    mRecordTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                    target:self
                                                  selector:@selector(updateRecordProgress:)
                                                  userInfo:nil
                                                   repeats:YES];
    [self.mLblRecording setText:@"Recording... 10s"];
    
    // Set settings for audio recording
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *sessionError;
    [session setCategory:AVAudioSessionCategoryRecord error:&sessionError];
    
    //录音设置
    NSMutableDictionary *settings = [[NSMutableDictionary alloc] init];
    //录音格式 无法使用
    [settings setValue :[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey: AVFormatIDKey];
    //采样率
    [settings setValue :[NSNumber numberWithFloat:44100.0] forKey: AVSampleRateKey];//44100.0
    //通道数
    [settings setValue :[NSNumber numberWithInt:2] forKey: AVNumberOfChannelsKey];
    //线性采样位数
    //[recordSettings setValue :[NSNumber numberWithInt:16] forKey: AVLinearPCMBitDepthKey];
    //音频质量,采样质量
    [settings setValue:[NSNumber numberWithInt:AVAudioQualityHigh] forKey:AVEncoderAudioQualityKey];
    
    
    mRecorder = [[AVAudioRecorder alloc] initWithURL:mRecordedFile settings:settings error:nil];
    [mRecorder prepareToRecord];
    [mRecorder record];
}

- (IBAction)onButRecord:(id)sender
{
    if (m_bRecording)
    {
        [self stopRecording];
        
        AVAudioSession *session = [AVAudioSession sharedInstance];
        NSError *sessionError;
        [session setCategory:AVAudioSessionCategoryPlayback error:&sessionError];
        
        
        [self.mViewRecording setHidden:YES];
        
        // set RecordPlay button
        [self updateButRecPlay];
        [self.mButRecPlay setHidden:NO];
        
        [self.mTxtComment becomeFirstResponder];
        
        [self.mTxtComment setHidden:NO];
        [self.mTxtComment setFrame:CGRectMake(40,
                                              self.mTxtComment.frame.origin.y,
                                              211,
                                              self.mTxtComment.frame.size.height)];
        
        // init record player
        NSError *playerError;
        mRecordPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:mRecordedFile error:&playerError];
        mRecordPlayer.volume = 5.0;
        if (!mRecordPlayer)
        {
            NSLog(@"Error creating player: %@", [playerError description]);
            return;
        }
        mRecordPlayer.delegate = self;
        
        [self.mButRecord setImage:[UIImage imageNamed:@"comment_rec_but.png"] forState:UIControlStateNormal];
        m_bRecording = NO;
    }
    else
    {
        [self.mTxtComment setHidden:YES];
        [self.mButRecPlay setHidden:YES];
        [self.mViewRecording setHidden:NO];
        
        [self stopRecording];
        
        mCurrentDate = [NSDate date];
        mRecordTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                        target:self
                                                      selector:@selector(updateRecordProgress:)
                                                      userInfo:nil
                                                       repeats:YES];
        [self.mLblRecording setText:@"Recording... 10s"];
        
        // Set settings for audio recording
        AVAudioSession *session = [AVAudioSession sharedInstance];
        NSError *sessionError;
        [session setCategory:AVAudioSessionCategoryRecord error:&sessionError];
        
        //录音设置
        NSMutableDictionary *settings = [[NSMutableDictionary alloc] init];
        //录音格式 无法使用
        [settings setValue :[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey: AVFormatIDKey];
        //采样率
        [settings setValue :[NSNumber numberWithFloat:44100.0] forKey: AVSampleRateKey];//44100.0
        //通道数
        [settings setValue :[NSNumber numberWithInt:2] forKey: AVNumberOfChannelsKey];
        //线性采样位数
        //[recordSettings setValue :[NSNumber numberWithInt:16] forKey: AVLinearPCMBitDepthKey];
        //音频质量,采样质量
        [settings setValue:[NSNumber numberWithInt:AVAudioQualityHigh] forKey:AVEncoderAudioQualityKey];
        
        
        mRecorder = [[AVAudioRecorder alloc] initWithURL:mRecordedFile settings:settings error:nil];
        [mRecorder prepareToRecord];
        [mRecorder record];
        
        
        [self.mButRecord setImage:[UIImage imageNamed:@"comment_rec_stop_but.png"] forState:UIControlStateNormal];
        m_bRecording = YES;
    }

}

- (IBAction)onButRecPlay:(id)sender
{
    //If the track is playing, pause and achange playButton text to "Play"
    if ([mRecordPlayer isPlaying])
    {
        [mRecordPlayer pause];
    }
    //If the track is not player, play the track and change the play button to "Pause"
    else
    {
        [mRecordPlayer play];
    }
    
    [self updateButRecPlay];
}

- (void)updateButRecPlay
{
    if (self.mZappData.type == 0)    // alert
    {
        if ([mRecordPlayer isPlaying])
        {
            [self.mButRecPlay setImage:[UIImage imageNamed:@"alert_pause_but.png"] forState:UIControlStateNormal];
        }
        else
        {
            [self.mButRecPlay setImage:[UIImage imageNamed:@"alert_play_but.png"] forState:UIControlStateNormal];
        }
    }
    else    // fun
    {
        if ([mRecordPlayer isPlaying])
        {
            [self.mButRecPlay setImage:[UIImage imageNamed:@"fun_pause_but.png"] forState:UIControlStateNormal];
        }
        else
        {
            [self.mButRecPlay setImage:[UIImage imageNamed:@"fun_play_but.png"] forState:UIControlStateNormal];
        }
    }
}

#pragma mark - AVAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [self updateButRecPlay];
}

#pragma mark - mail delegate
- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error
{
	if (result != MFMailComposeResultSent) {
        //        NSString *strMessage;
        //
        //        if (controller == mailerShare) {
        //            strMessage = @"Email Share has been failed.";
        //        }
        //        else {
        //            strMessage = @"Report has been failed.";
        //        }
        //
        //        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Email Share has been failed." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        //        [alert show];
	}
    
	[self.navigationController dismissViewControllerAnimated:YES completion:nil];
}


@end
