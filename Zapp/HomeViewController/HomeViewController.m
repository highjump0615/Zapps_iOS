//
//  HomeViewController.m
//  Zapp
//
//  Created by highjump on 14-7-10.
//  Copyright (c) 2014年 Tian. All rights reserved.
//

#import "HomeViewController.h"
#import "HomeFeedCell.h"
#import "ProfileViewController.h"

#import "CircleProgressView.h"

#import <QuartzCore/QuartzCore.h>
#import <Accelerate/Accelerate.h>

#import "PlaceholderTextView.h"
#import "MBProgressHUD.h"

#import "CommentViewController.h"
#import "ShareView.h"

#import <AudioToolbox/AudioServices.h>

#import "EGORefreshTableHeaderView.h"
#import "EGORefreshTableFooterView.h"

#import <MessageUI/MFMailComposeViewController.h>


@interface HomeViewController () <MFMailComposeViewControllerDelegate, AVAudioPlayerDelegate, CLLocationManagerDelegate, UpdateLikeCommentDelegate, EGORefreshTableDelegate, HideDelegate>
{
    int m_nShareShowYPos;
    int m_nShareHideYPos;
    
    NSTimer *mRecordTimer;
    NSDate *mCurrentDate;
    NSDate *mTargetDate;
    CircleProgressView *mCircleView;
    
    UIView *mBlurView;
    
    // Save Zapp view
    int mnSaveMode;
    int mbSaveShareMode;
    
    AVAudioRecorder *mRecorder;
    AVAudioPlayer *mRecordPlayer;
    NSURL *mRecordedFile;
    NSURL *mRecordedFileMp3;
    
    // location
    CLLocationManager *mLocationManager;
    
    int m_nCurrnetCount;
    int m_nCountOnce;    
    
    int m_nCurZappNum;

    //EGOHeader
    EGORefreshTableHeaderView *_refreshHeaderView;
    //EGOFoot
    EGORefreshTableFooterView *_refreshFooterView;
    //
    BOOL _reloading;
    
    MBProgressHUD *m_hud;
    
    NSDate *mLocationTimeTemp;
}

@property (weak, nonatomic) IBOutlet UIView *mViewHeader;
@property (weak, nonatomic) IBOutlet UISegmentedControl *mSegementType;

@property (weak, nonatomic) IBOutlet UITableView *mTableView;
@property (weak, nonatomic) IBOutlet ShareView *mViewShare;
@property (weak, nonatomic) IBOutlet UIView *mViewPopupMask;

@property (weak, nonatomic) IBOutlet UIButton *mButRecord;

@property (weak, nonatomic) IBOutlet UIView  *mViewRecord;
@property (weak, nonatomic) IBOutlet UILabel *mLblRecord;

@property (weak, nonatomic) IBOutlet UIView *mViewSave;
@property (weak, nonatomic) IBOutlet UIButton *mViewSaveButClose;
@property (weak, nonatomic) IBOutlet UIView *mViewSaveViewContent;
@property (weak, nonatomic) IBOutlet UIButton *mViewSaveButPlay;
@property (weak, nonatomic) IBOutlet UIButton *mViewSaveButAlert;
@property (weak, nonatomic) IBOutlet UIButton *mViewSaveButFun;
@property (weak, nonatomic) IBOutlet UIButton *mViewSaveButShare;
@property (weak, nonatomic) IBOutlet UILabel *mViewSaveLblDist;
@property (weak, nonatomic) IBOutlet UISlider *mViewSaveSliderDist;
@property (weak, nonatomic) IBOutlet UIButton *mViewSaveButFacebook;
@property (weak, nonatomic) IBOutlet UIButton *mViewSaveButTwitter;
@property (weak, nonatomic) IBOutlet UIView *mViewSaveViewSegment;
@property (weak, nonatomic) IBOutlet PlaceholderTextView *mViewSaveTxtContent;


@end

@implementation HomeViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.mSegementType addTarget:self
                           action:@selector(onChangeSegment:forEvent:)
                 forControlEvents:UIControlEventValueChanged];
    
    m_nShareHideYPos = self.view.frame.size.height + 3;
    m_nShareShowYPos = m_nShareHideYPos - self.mViewShare.frame.size.height;
    
    // shadow on share panel
    [self.mViewShare showShadow];
    self.mViewShare.delegate = self;
    
    [self.mViewShare setFrame:CGRectMake(0, m_nShareHideYPos, self.mViewShare.frame.size.width, self.mViewShare.frame.size.height)];
    
    // record area
    [self.mViewRecord.layer setMasksToBounds:YES];
    [self.mViewRecord.layer setCornerRadius:135.0];
    self.mViewRecord.layer.masksToBounds = NO;

    self.mViewRecord.layer.shadowColor = [UIColor blackColor].CGColor;
    self.mViewRecord.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
    self.mViewRecord.layer.shadowOpacity = 0.3f;
    
    [self.mViewRecord setHidden:YES];
    [self.mViewSave setHidden:YES];
    
    // view save
    [self.mViewSaveViewContent.layer setCornerRadius:10.0];
    self.mViewSaveViewContent.layer.shadowColor = [UIColor blackColor].CGColor;
    self.mViewSaveViewContent.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
    self.mViewSaveViewContent.layer.shadowOpacity = 0.3f;
    
    [self.mViewSaveButClose setFrame:CGRectMake(self.mViewSaveViewContent.frame.origin.x + self.mViewSaveViewContent.frame.size.width - 35,
                                               self.mViewSaveViewContent.frame.origin.y - 25,
                                               self.mViewSaveButClose.frame.size.width,
                                                self.mViewSaveButClose.frame.size.height)];
    
    // initializing record
    mRecordedFile = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingString:@"RecordedFile.caf"]];
    mRecordedFileMp3 = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingString:@"RecordedFile.mp3"]];

    AVAudioSession *session = [AVAudioSession sharedInstance];
    
    NSError *sessionError;
    
    [session setCategory:AVAudioSessionCategoryPlayback error:&sessionError];
    //    [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&sessionError];
    
    if(session == nil)
        NSLog(@"Error creating session: %@", [sessionError description]);
    else
        [session setActive:YES error:nil];
    ////////////////////

    
    [self.mViewSaveTxtContent setPlaceholder:@"Add a description..."];
    
    // set location
    if (nil == mLocationManager) {
		mLocationManager = [[CLLocationManager alloc] init];
	}
    
    mLocationManager.delegate = self;
    mLocationManager.distanceFilter = 500; // meters
	mLocationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    
    CommonUtils *utils = [CommonUtils sharedObject];
    PFUser *currentUser = [PFUser currentUser];
    PFGeoPoint *currentPoint = (PFGeoPoint *)currentUser[@"location"];
    CLLocation *newLocation = [[CLLocation alloc] initWithLatitude:currentPoint.latitude longitude:currentPoint.longitude];
    utils.mCurrentLocation = newLocation;
    
    m_nCountOnce = 5;
    m_nCurrnetCount = 0;
    
    utils.mbNeedRefresh = NO;
    
    [self getBlog:YES];
    
    // notification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(checkNotification)
                                                 name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)checkNotification
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    CommonUtils *utils = [CommonUtils sharedObject];
    // check push notification
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    
    if (currentInstallation.badge > 0)
    {
        currentInstallation.badge = 0;
        [currentInstallation saveEventually];
        
        [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
        
        if (utils.strNotifyType.length > 0)
        {
            if ([utils.strNotifyType isEqualToString:@"zapp"])
            {
                [utils.notifyZappObj fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error)
                {
                    ZappData *zapp = [[ZappData alloc] initWithZapp:object];
                    [utils.mZappList addObject:zapp];
                }];
            }
            
            m_nCurZappNum = -1;
            [self performSegueWithIdentifier:@"Home2Comment" sender:nil];
            utils.strNotifyType = @"";
        }
    }
}

- (void)saveUserLocation:(CLLocation *)location
{
    if (location)
    {
        PFUser *currentUser = [PFUser currentUser];
        CommonUtils *utils = [CommonUtils sharedObject];
        utils.mCurrentLocation = location;
        
        // save to backend
        CLLocationCoordinate2D currentCoordinate = utils.mCurrentLocation.coordinate;
        PFGeoPoint *currentPoint = [PFGeoPoint geoPointWithLatitude:currentCoordinate.latitude longitude:currentCoordinate.longitude];
        currentUser[@"location"] = currentPoint;
        
        [currentUser saveInBackground];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [mLocationManager startUpdatingLocation];
    
    CommonUtils *utils = [CommonUtils sharedObject];
    
    if (utils.mbNeedRefresh)
    {
        m_nCurrnetCount = 0;
        [self getBlog:YES];
    }
    else
    {
        if (utils.mZappList.count > 0)
        {
            for (ZappData *zapp in utils.mZappList)
            {
                [self getLikeCommentInfo:zapp];
            }
            m_nCurrnetCount = (int)utils.mZappList.count;
        }

        [self.mTableView reloadData];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    CommonUtils *utils = [CommonUtils sharedObject];
    [utils stopCurrentPlaying];
    
    [mLocationManager stopUpdatingLocation];
}

- (void)viewWillAppear:(BOOL)animated
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onButProfile:(id)sender
{
    m_nCurZappNum = -1;
    [self performSegueWithIdentifier:@"Home2Profile" sender:nil];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    CommonUtils *utils = [CommonUtils sharedObject];
    
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([[segue identifier] isEqualToString:@"Home2Profile"])
    {
        ProfileViewController *profileView = (ProfileViewController *)[segue destinationViewController];
        
        if (m_nCurZappNum >= 0)
        {
            ZappData *zapp = [utils.mZappList objectAtIndex:m_nCurZappNum];
            profileView.mUser = zapp.user;
        }
        else
        {
            profileView.mUser = [PFUser currentUser];
        }
    }
    else if ([[segue identifier] isEqualToString:@"Home2Comment"])
    {
        CommentViewController *commentViewController = [segue destinationViewController];
        commentViewController.delegate = self;
        
        if (m_nCurZappNum >= 0)
        {
            commentViewController.mZappData = [utils.mZappList objectAtIndex:m_nCurZappNum];
        }
        else
        {
            CommonUtils *utils = [CommonUtils sharedObject];
            
            PFObject *objZapp = utils.notifyZappObj;
            
            ZappData *zapp = [[ZappData alloc] init];
            
            zapp.strId = objZapp.objectId;
            zapp.object = objZapp;
            zapp.bLiked = -1;
            
            commentViewController.mZappData = zapp;
            utils.notifyZappObj = nil;
        }
    }
}

#pragma mark - Segment

- (void)onChangeSegment:(id)sender forEvent:(UIEvent *)event
{
    int nType = (int)self.mSegementType.selectedSegmentIndex;
    
    if (nType == 0) // alert
    {
        [self.mViewHeader setBackgroundColor:[UIColor colorWithRed:239/255.0 green:80/255.0 blue:110/255.0 alpha:1]];
    }
    else if (nType == 1) // all
    {
        [self.mViewHeader setBackgroundColor:[UIColor colorWithRed:149/255.0 green:134/255.0 blue:164/255.0 alpha:1]];
    }
    else if (nType == 2) // fun
    {
        [self.mViewHeader setBackgroundColor:[UIColor colorWithRed:138/255.0 green:172/255.0 blue:228/255.0 alpha:1]];
    }
    
    CommonUtils *utils = [CommonUtils sharedObject];
    [utils stopCurrentPlaying];
    
    m_nCurrnetCount = 0;
    [self getBlog:YES];
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

- (IBAction)onButRecord:(id)sender
{
    [self.mViewRecord setHidden:NO];
    
    if (mRecordTimer)
    {
        [self stopRecording];
        [mRecordTimer invalidate];
        mRecordTimer = nil;
    }
    
    if (!mCircleView)
    {
        mCircleView = [[CircleProgressView alloc] initWithFrame:CGRectMake(0, 0, self.mViewRecord.frame.size.width, self.mViewRecord.frame.size.height)];
        [self.mViewRecord insertSubview:mCircleView atIndex:0];
    }
    
    mCurrentDate = [NSDate date];
    
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    
    [comps setSecond:10];
    
    mTargetDate = [gregorian dateByAddingComponents:comps toDate:mCurrentDate options:0];;

    
    mRecordTimer = [NSTimer scheduledTimerWithTimeInterval:0.01
                                                    target:self
                                                  selector:@selector(updateCircleProgress:)
                                                  userInfo:nil
                                                   repeats:YES];
    
    // Set settings for audio recording
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *sessionError;
    [session setCategory:AVAudioSessionCategoryRecord error:&sessionError];
    
    //录音设置
    NSMutableDictionary *settings = [[NSMutableDictionary alloc] init];
    //录音格式 无法使用
    [settings setValue :[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey: AVFormatIDKey];
    //采样率
    [settings setValue :[NSNumber numberWithFloat:44100] forKey: AVSampleRateKey];//44100.0
    //通道数
    [settings setValue :[NSNumber numberWithInt:2] forKey: AVNumberOfChannelsKey];
//    [settings setValue :[NSNumber numberWithInt:128000] forKey: AVEncoderBitRateKey];
    
    //线性采样位数
    //[recordSettings setValue :[NSNumber numberWithInt:16] forKey: AVLinearPCMBitDepthKey];
    //音频质量,采样质量
    [settings setValue:[NSNumber numberWithInt:AVAudioQualityHigh] forKey:AVEncoderAudioQualityKey];
    

    mRecorder = [[AVAudioRecorder alloc] initWithURL:mRecordedFile settings:settings error:nil];
    [mRecorder prepareToRecord];
    [mRecorder record];
}

- (void)stopRecording
{
    if (mRecorder)
    {
        [mRecorder stop];
        mRecorder = nil;
    }
}

- (void)updateCircleProgress:(NSTimer *)theTimer
{
    NSTimeInterval interval = 0;
    interval = [[NSDate date] timeIntervalSinceDate:mCurrentDate];

    [self.mLblRecord setText:[NSString stringWithFormat:@"%.2f", interval]];
    mCircleView.mfPercentageCompleted = interval / 10.0 * 100;
    [mCircleView setNeedsDisplay];
    
    if (interval >= 10.0)
    {
        [self stopRecording];
        [mRecordTimer invalidate];
        mRecordTimer = nil;
    }
}

- (void)closeRecord
{
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *sessionError;
    [session setCategory:AVAudioSessionCategoryPlayback error:&sessionError];
    
    if (mRecordTimer)
    {
        [self stopRecording];
        [mRecordTimer invalidate];
        mRecordTimer = nil;
    }
    [self.mViewRecord setHidden:YES];
}

- (IBAction)onRecordOk:(id)sender {
    
    [self closeRecord];
    [self.mButRecord setHidden:YES];
    
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
    
    // init save dialog
    mbSaveShareMode = -1;
    mnSaveMode = 0; // alert
    
    [self.mViewSaveTxtContent setText:@""];
    [self.mViewSaveSliderDist setValue:50];
    [self.mViewSaveLblDist setText:[NSString stringWithFormat:@"%dKM", (int)self.mViewSaveSliderDist.value]];
    
    [self updateSaveView];
    
    mBlurView = [[UIView alloc] initWithFrame:self.view.bounds];
    mBlurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view insertSubview:mBlurView aboveSubview:self.mButRecord];
    
    [self createScreenshotAndLayoutWithScreenshotCompletion:^{
        [self.mViewSave setHidden:NO];
    }];
    
}

- (IBAction)onRecordCancel:(id)sender {
    [self closeRecord];
}


- (void)cleanupBlur {
    [mBlurView removeFromSuperview];
    mBlurView = nil;

    [self.mButRecord setHidden:NO];
    [self.mViewSave setHidden:YES];
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


#pragma mark - TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    int nCount = 0;
    CommonUtils *utils = [CommonUtils sharedObject];
    
    if (utils.mZappList)
    {
        nCount = (int)[utils.mZappList count];
    }
    
    return nCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HomeFeedCell *feedCell = (HomeFeedCell *)[tableView dequeueReusableCellWithIdentifier:@"HomeListCell"];
    feedCell.mnMode = 0;
//    [feedCell swipeMenu];
    
    CommonUtils *utils = [CommonUtils sharedObject];
    if (utils.mZappList && utils.mZappList.count > 0)
    {
        ZappData *zapp = [utils.mZappList objectAtIndex:indexPath.row];
        [feedCell fillContent:zapp];
    }
    
    [feedCell.mButUser addTarget:self action:@selector(onBtnUserPhoto:) forControlEvents:UIControlEventTouchUpInside];
    feedCell.mButUser.tag = indexPath.row;
    
    // comment button
    [feedCell.mButComment addTarget:self action:@selector(onBtnComment:) forControlEvents:UIControlEventTouchUpInside];
    feedCell.mButComment.tag = indexPath.row;
    
    [feedCell.mButReport addTarget:self action:@selector(onListReport:) forControlEvents:UIControlEventTouchUpInside];
//    feedCell.mBtnUsername.tag = indexPath.row;
    
    [feedCell.mButShare addTarget:self action:@selector(onListShare:) forControlEvents:UIControlEventTouchUpInside];
    feedCell.mButShare.tag = indexPath.row;
    
    return feedCell;
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([tableView.indexPathsForVisibleRows indexOfObject:indexPath] == NSNotFound)
    {
        HomeFeedCell *feedCell = (HomeFeedCell *)cell;
        [feedCell stopPlaying];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int nHeight;
    CommonUtils *utils = [CommonUtils sharedObject];
    ZappData *zapp = [utils.mZappList objectAtIndex:indexPath.row];

    nHeight = [CommonUtils getHeight:zapp.strDescription fontsize:13 width:241 height:0] + TEXT_FACTOR;

    return nHeight;
}


#pragma mark - List
- (void)onBtnUserPhoto:(id)sender
{
    m_nCurZappNum = (int)((UIButton*)sender).tag;
    
    CommonUtils *utils = [CommonUtils sharedObject];
    ZappData *zapp = [utils.mZappList objectAtIndex:m_nCurZappNum];
    if ([zapp.user.objectId isEqualToString:[PFUser currentUser].objectId]) {
        return;
    }
    
    [self performSegueWithIdentifier:@"Home2Profile" sender:nil];
}

- (void)onBtnComment:(id)sender {
    m_nCurZappNum = (int)((UIButton*)sender).tag;
    [self performSegueWithIdentifier:@"Home2Comment" sender:nil];
}

- (void)onListReport:(id)sender
{
    CommonUtils *utils = [CommonUtils sharedObject];
    [utils reportEmail:self];
}

- (void)onListShare:(id)sender
{
    m_nCurZappNum = (int)((UIButton*)sender).tag;
    
    CommonUtils *utils = [CommonUtils sharedObject];
    ZappData *zapp = [utils.mZappList objectAtIndex:m_nCurZappNum];
    
    [self.mViewShare setZappData:zapp];
    
    if (self.mViewShare.frame.origin.y == m_nShareHideYPos) {
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

- (UIImage *)rn_screenshot {
    UIGraphicsBeginImageContext(self.view.bounds.size);
    [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // helps w/ our colors when blurring
    // feel free to adjust jpeg quality (lower = higher perf)
    NSData *imageData = UIImageJPEGRepresentation(image, 0.75);
    image = [UIImage imageWithData:imageData];
    
    return image;
}

-(UIImage *)rn_boxblurImageWithBlur:(UIImage *)image blur:(CGFloat)blur exclusionPath:(UIBezierPath *)exclusionPath {
    if (blur < 0.f || blur > 1.f) {
        blur = 0.5f;
    }
    
    int boxSize = (int)(blur * 40);
    boxSize = boxSize - (boxSize % 2) + 1;
    
    CGImageRef img = image.CGImage;
    vImage_Buffer inBuffer, outBuffer;
    vImage_Error error;
    void *pixelBuffer;
    
    // create unchanged copy of the area inside the exclusionPath
    UIImage *unblurredImage = nil;
    if (exclusionPath != nil) {
        CAShapeLayer *maskLayer = [CAShapeLayer new];
        maskLayer.frame = (CGRect){CGPointZero, image.size};
        maskLayer.backgroundColor = [UIColor blackColor].CGColor;
        maskLayer.fillColor = [UIColor whiteColor].CGColor;
        maskLayer.path = exclusionPath.CGPath;
        
        // create grayscale image to mask context
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
        CGContextRef context = CGBitmapContextCreate(nil, maskLayer.bounds.size.width, maskLayer.bounds.size.height, 8, 0, colorSpace, kCGImageAlphaNone);
        CGContextTranslateCTM(context, 0, maskLayer.bounds.size.height);
        CGContextScaleCTM(context, 1.f, -1.f);
        [maskLayer renderInContext:context];
        CGImageRef imageRef = CGBitmapContextCreateImage(context);
        UIImage *maskImage = [UIImage imageWithCGImage:imageRef];
        CGImageRelease(imageRef);
        CGColorSpaceRelease(colorSpace);
        CGContextRelease(context);
        
        UIGraphicsBeginImageContext(image.size);
        context = UIGraphicsGetCurrentContext();
        CGContextTranslateCTM(context, 0, maskLayer.bounds.size.height);
        CGContextScaleCTM(context, 1.f, -1.f);
        CGContextClipToMask(context, maskLayer.bounds, maskImage.CGImage);
        CGContextDrawImage(context, maskLayer.bounds, image.CGImage);
        unblurredImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    //create vImage_Buffer with data from CGImageRef
    CGDataProviderRef inProvider = CGImageGetDataProvider(img);
    CFDataRef inBitmapData = CGDataProviderCopyData(inProvider);
    
    inBuffer.width = CGImageGetWidth(img);
    inBuffer.height = CGImageGetHeight(img);
    inBuffer.rowBytes = CGImageGetBytesPerRow(img);
    
    inBuffer.data = (void*)CFDataGetBytePtr(inBitmapData);
    
    //create vImage_Buffer for output
    pixelBuffer = malloc(CGImageGetBytesPerRow(img) * CGImageGetHeight(img));
    
    if(pixelBuffer == NULL)
        NSLog(@"No pixelbuffer");
    
    outBuffer.data = pixelBuffer;
    outBuffer.width = CGImageGetWidth(img);
    outBuffer.height = CGImageGetHeight(img);
    outBuffer.rowBytes = CGImageGetBytesPerRow(img);
    
    // Create a third buffer for intermediate processing
    void *pixelBuffer2 = malloc(CGImageGetBytesPerRow(img) * CGImageGetHeight(img));
    vImage_Buffer outBuffer2;
    outBuffer2.data = pixelBuffer2;
    outBuffer2.width = CGImageGetWidth(img);
    outBuffer2.height = CGImageGetHeight(img);
    outBuffer2.rowBytes = CGImageGetBytesPerRow(img);
    
    //perform convolution
    error = vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer2, NULL, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend);
    error = vImageBoxConvolve_ARGB8888(&outBuffer2, &inBuffer, NULL, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend);
    error = vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer, NULL, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend);
    
    if (error) {
        NSLog(@"error from convolution %ld", error);
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(outBuffer.data,
                                             outBuffer.width,
                                             outBuffer.height,
                                             8,
                                             outBuffer.rowBytes,
                                             colorSpace,
                                             kCGImageAlphaNoneSkipLast);
    CGImageRef imageRef = CGBitmapContextCreateImage(ctx);
    UIImage *returnImage = [UIImage imageWithCGImage:imageRef];
    
    // overlay images?
    if (unblurredImage != nil) {
        UIGraphicsBeginImageContext(returnImage.size);
        [returnImage drawAtPoint:CGPointZero];
        [unblurredImage drawAtPoint:CGPointZero];
        
        returnImage = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
    }
    
    //clean up
    CGContextRelease(ctx);
    CGColorSpaceRelease(colorSpace);
    free(pixelBuffer);
    free(pixelBuffer2);
    CFRelease(inBitmapData);
    CGImageRelease(imageRef);
    
    return returnImage;
}

- (void)createScreenshotAndLayoutWithScreenshotCompletion:(dispatch_block_t)screenshotCompletion {
    mBlurView.alpha = 0.f;
    
    UIImage *screenshot = [self rn_screenshot];
    mBlurView.alpha = 1.f;
    mBlurView.layer.contents = (id)screenshot.CGImage;
    
    if (screenshotCompletion != nil) {
        screenshotCompletion();
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0L), ^{
        UIImage *blur = [self rn_boxblurImageWithBlur:screenshot blur:0.3 exclusionPath:nil];

        dispatch_async(dispatch_get_main_queue(), ^{
            CATransition *transition = [CATransition animation];
            
            transition.duration = 0.2;
            transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            transition.type = kCATransitionFade;
            
            [mBlurView.layer addAnimation:transition forKey:nil];
            mBlurView.layer.contents = (id)blur.CGImage;
            
            [self.view setNeedsLayout];
            [self.view layoutIfNeeded];
        });
    });
}

#pragma mark Save zapp view
#pragma mark TextField Delegate
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    
    return YES;
}

- (void)updateSaveView
{
    if (mnSaveMode == 0)    // alert
    {
        if ([mRecordPlayer isPlaying])
        {
            [self.mViewSaveButPlay setImage:[UIImage imageNamed:@"alert_pause_but.png"] forState:UIControlStateNormal];
        }
        else
        {
            [self.mViewSaveButPlay setImage:[UIImage imageNamed:@"alert_play_but.png"] forState:UIControlStateNormal];
        }
        
        [self.mViewSaveButAlert setImage:[UIImage imageNamed:@"save_seg_alert_on.png"] forState:UIControlStateNormal];
        [self.mViewSaveButFun setImage:[UIImage imageNamed:@"save_seg_fun_off.png"] forState:UIControlStateNormal];
        [self.mViewSaveButShare setImage:[UIImage imageNamed:@"save_share_alert_but.png"] forState:UIControlStateNormal];
        
        [self.mViewSaveViewSegment bringSubviewToFront:self.mViewSaveButAlert];
    }
    else    // fun
    {
        if ([mRecordPlayer isPlaying])
        {
            [self.mViewSaveButPlay setImage:[UIImage imageNamed:@"fun_pause_but.png"] forState:UIControlStateNormal];
        }
        else
        {
            [self.mViewSaveButPlay setImage:[UIImage imageNamed:@"fun_play_but.png"] forState:UIControlStateNormal];
        }
        
        [self.mViewSaveButAlert setImage:[UIImage imageNamed:@"save_seg_alert_off.png"] forState:UIControlStateNormal];
        [self.mViewSaveButFun setImage:[UIImage imageNamed:@"save_seg_fun_on.png"] forState:UIControlStateNormal];
        [self.mViewSaveButShare setImage:[UIImage imageNamed:@"save_share_fun_but.png"] forState:UIControlStateNormal];

        [self.mViewSaveViewSegment bringSubviewToFront:self.mViewSaveButFun];
    }


    [self.mViewSaveButFacebook setImage:[UIImage imageNamed:@"save_facebook_off_but.png"] forState:UIControlStateNormal];
    [self.mViewSaveButTwitter setImage:[UIImage imageNamed:@"save_twitter_off_but.png"] forState:UIControlStateNormal];
    
    if (mbSaveShareMode == 0)       // facebook
    {
        [self.mViewSaveButFacebook setImage:[UIImage imageNamed:@"save_facebook_on_but.png"] forState:UIControlStateNormal];
        [self.mViewSaveButTwitter setImage:[UIImage imageNamed:@"save_twitter_off_but.png"] forState:UIControlStateNormal];
    }
    else if (mbSaveShareMode == 1)  // twitter
    {
        [self.mViewSaveButFacebook setImage:[UIImage imageNamed:@"save_facebook_off_but.png"] forState:UIControlStateNormal];
        [self.mViewSaveButTwitter setImage:[UIImage imageNamed:@"save_twitter_on_but.png"] forState:UIControlStateNormal];
    }
}

- (IBAction)onSaveFun:(id)sender
{
    mnSaveMode = 1; // fun
    [self updateSaveView];
}

- (IBAction)onSaveAlert:(id)sender
{
    mnSaveMode = 0; // alert
    [self updateSaveView];
}

- (IBAction)onSavePlay:(id)sender
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

    [self updateSaveView];
}

- (IBAction)onSaveDistanceSlider:(id)sender
{
    NSString *strDistance = [NSString stringWithFormat:@"%dKM", (int)self.mViewSaveSliderDist.value];
    [self.mViewSaveLblDist setText:strDistance];
}

- (IBAction)onSaveFacebook:(id)sender
{
    if (mbSaveShareMode != 0)
    {
        mbSaveShareMode = 0;
    }
    else
    {
        mbSaveShareMode = -1;
    }
    
    [self updateSaveView];
}

- (IBAction)onSaveTwitter:(id)sender
{
    if (mbSaveShareMode != 1)
    {
        mbSaveShareMode = 1;
    }
    else
    {
        mbSaveShareMode = -1;
    }
    
    [self updateSaveView];
}

- (IBAction)onSaveShare:(id)sender
{
    if (!self.mViewSaveTxtContent.text.length) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"Input the description" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		return;
    }
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [hud setLabelText:@"Processing Audio Data..."];
    
    CommonUtils *utils = [CommonUtils sharedObject];
    if ([utils convertToMp3:mRecordedFile destination:mRecordedFileMp3] == NO)
    {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        return;
    }
    
    // save to zapp objects
    PFObject *zappObj = [PFObject objectWithClassName:@"Zapps"];
    zappObj[@"username"] = [CommonUtils getUsernameToShow:[PFUser currentUser]];
    zappObj[@"type"] = @(mnSaveMode);
    zappObj[@"user"] = [PFUser currentUser];
    zappObj[@"description"] = self.mViewSaveTxtContent.text;
    zappObj[@"range"] = [NSNumber numberWithInteger:(int)self.mViewSaveSliderDist.value];
    
    // save location
    CLLocationCoordinate2D currentCoordinate = utils.mCurrentLocation.coordinate;
	PFGeoPoint *currentPoint = [PFGeoPoint geoPointWithLatitude:currentCoordinate.latitude longitude:currentCoordinate.longitude];
    zappObj[@"location"] = currentPoint;
    
    // upload mp3 data
    NSData *zappData = [NSData dataWithContentsOfURL:mRecordedFileMp3];
    NSLog(@"mp3 length  :%lu", (unsigned long)zappData.length);
    zappObj[@"zapp"] = [PFFile fileWithName:@"zapp.mp3" data:zappData];

    [hud setLabelText:@"Saving Data..."];

    [zappObj saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
    {
        PFUser *currentUser = [PFUser currentUser];
        
        ZappData *zappNew = [[ZappData alloc] initWithZapp:zappObj];
        zappNew.bLiked = 0;
        [utils.mZappList insertObject:zappNew atIndex:0];
        
        // update zapp count of the user
        int nZappCount = [currentUser[@"zappcount"] intValue];
        currentUser[@"zappcount"] = [NSNumber numberWithInt:nZappCount + 1];
        [currentUser saveInBackground];
        
        // facebook twitter share
        PFFile *zappfile = zappObj[@"zapp"];
        if (mbSaveShareMode == 0)   // facebook
        {
            [utils shareToFacebook:self text:self.mViewSaveTxtContent.text url:zappfile.url];
        }
        else if (mbSaveShareMode == 1)  // twitter
        {
            [utils shareToTwitter:self text:self.mViewSaveTxtContent.text url:zappfile.url];
        }
        
        //
        // send notification to the user around here
        //
        PFQuery *query = [PFUser query];
        [query whereKey:@"distanceFilter" equalTo:[NSNumber numberWithBool:YES]];
        [query whereKey:@"objectId" notEqualTo:currentUser.objectId];
        
        PFGeoPoint *point = [PFGeoPoint geoPointWithLatitude:utils.mCurrentLocation.coordinate.latitude longitude:utils.mCurrentLocation.coordinate.longitude];
        [query whereKey:@"location" nearGeoPoint:point withinKilometers:self.mViewSaveSliderDist.value];
        
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
         {
             PFQuery *pushQuery = [PFInstallation query];
             [pushQuery whereKey:@"user" containedIn:objects];
             
             // Send the notification.
             PFPush *push = [[PFPush alloc] init];
             [push setQuery:pushQuery];
             
             NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
                                   self.mViewSaveTxtContent.text, @"alert",
                                   @"zapp", @"notifyType",
                                   zappObj.objectId, @"notifyZapp",
                                   @"Increment", @"badge",
                                   @"cheering.caf", @"sound",
                                   nil];
             [push setData:data];
             
             [push sendPushInBackground];
         }];
        
        
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [self onSaveClose:nil];
        
        
    }];
    
}

- (IBAction)onSaveClose:(id)sender
{
    [self.view endEditing:YES];
    
    CommonUtils *utils = [CommonUtils sharedObject];
    
    CABasicAnimation *opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    opacityAnimation.fromValue = @1.;
    opacityAnimation.toValue = @0.;
    opacityAnimation.duration = 0.2;
    [mBlurView.layer addAnimation:opacityAnimation forKey:nil];
    
    mBlurView.layer.opacity = 0;
    [self performSelector:@selector(cleanupBlur) withObject:nil afterDelay:opacityAnimation.duration];
    
    [self.mTableView reloadData];
    
    if (utils.mZappList.count > m_nCountOnce)
    {
        [self setFooterView];
    }
}


#pragma mark - AVAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [self updateSaveView];
}

#pragma mark - CLLocationManagerDelegate methods and helpers

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
	NSLog(@"%s", __PRETTY_FUNCTION__);
	switch (status) {
		case kCLAuthorizationStatusAuthorized:
			NSLog(@"kCLAuthorizationStatusAuthorized");
			// Re-enable the post button if it was disabled before.
			self.navigationItem.rightBarButtonItem.enabled = YES;
			[mLocationManager startUpdatingLocation];
			break;
		case kCLAuthorizationStatusDenied:
			NSLog(@"kCLAuthorizationStatusDenied");
        {{
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Zapp can’t access your current location.\n\nTo view nearby posts or create a post at your current location, turn on access for Zapp to your location in the Settings app under Location Services." message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alertView show];
            // Disable the post button.
            self.navigationItem.rightBarButtonItem.enabled = NO;
        }}
			break;
		case kCLAuthorizationStatusNotDetermined:
			NSLog(@"kCLAuthorizationStatusNotDetermined");
			break;
		case kCLAuthorizationStatusRestricted:
			NSLog(@"kCLAuthorizationStatusRestricted");
			break;
	}
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
	NSLog(@"%s", __PRETTY_FUNCTION__);
    
    // test the age of the location measurement to determine if the measurement is cached
    // in most cases you will not want to rely on cached measurements
    NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
    
    if (locationAge > 5.0) return;
    
    // test that the horizontal accuracy does not indicate an invalid measurement
    if (newLocation.horizontalAccuracy < 0) return;

    CommonUtils *utils = [CommonUtils sharedObject];
    
    if (mLocationTimeTemp)
    {
        NSTimeInterval howRecent = [mLocationTimeTemp timeIntervalSinceNow];
        if (abs(howRecent) < 5.0)
        {
            return;
        }
    }
    
    mLocationTimeTemp = newLocation.timestamp;
    
    // calculate the distance
    CLLocationCoordinate2D currentCoordinate = utils.mCurrentLocation.coordinate;
	PFGeoPoint *currentPoint = [PFGeoPoint geoPointWithLatitude:currentCoordinate.latitude longitude:currentCoordinate.longitude];
    CLLocationCoordinate2D newCoordinate = mLocationManager.location.coordinate;
    PFGeoPoint *zappPoint = [PFGeoPoint geoPointWithLatitude:newCoordinate.latitude longitude:newCoordinate.longitude];;
    
    double distanceDouble = [currentPoint distanceInKilometersTo:zappPoint];
    double distanceDoubleMeter = [newLocation distanceFromLocation:utils.mCurrentLocation];
    
    NSLog(@"distance: %fkm, %fm", distanceDouble, distanceDoubleMeter);
    
    if (distanceDouble >= 0.1)
    {
        [self saveUserLocation:newLocation];
        
        PFUser *currentUser = [PFUser currentUser];
        if (currentUser[@"distanceFilter"] == [NSNumber numberWithBool:YES])
        {
            UIViewController *viewController = [[self navigationController] topViewController];
            
            if ([viewController isKindOfClass:[HomeViewController class]])
            {
                m_nCurrnetCount = 0;
                [self getBlog:YES];
            }
            else
            {
                CommonUtils *utils = [CommonUtils sharedObject];
                utils.mbNeedRefresh = YES;
            }
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
	NSLog(@"%s", __PRETTY_FUNCTION__);
	NSLog(@"Error: %@", [error description]);
    
	if (error.code == kCLErrorDenied) {
		[mLocationManager stopUpdatingLocation];
	} else if (error.code == kCLErrorLocationUnknown) {
		// todo: retry?
		// set a timer for five seconds to cycle location, and if it fails again, bail and tell the user.
        [mLocationManager stopUpdatingLocation];
	} else {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error retrieving location"
		                                                message:[error description]
		                                               delegate:nil
		                                      cancelButtonTitle:nil
		                                      otherButtonTitles:@"Ok", nil];
		[alert show];
	}
}


# pragma mark - Zapp Related 
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
            
            [self.mTableView reloadData];
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
        
        [self.mTableView reloadData];
    }];
    
}

- (void)getBlog:(BOOL)bShowLoading
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    PFQuery *query = [PFQuery queryWithClassName:@"Zapps"];
    CommonUtils *utils = [CommonUtils sharedObject];
    
    // query type
    int nType = (int)self.mSegementType.selectedSegmentIndex;
    if (nType == 0)
    {
        [query whereKey:@"type" equalTo:[NSNumber numberWithInteger:0]];
    }
    else if (nType == 2)
    {
        [query whereKey:@"type" equalTo:[NSNumber numberWithInteger:1]];
    }
    
    PFUser *currentUser = [PFUser currentUser];
    
    if ([currentUser[@"distanceFilter"] boolValue])
    {
        // Query for posts sort of kind of near our current location.
        PFGeoPoint *point = [PFGeoPoint geoPointWithLatitude:utils.mCurrentLocation.coordinate.latitude longitude:utils.mCurrentLocation.coordinate.longitude];
        [query whereKey:@"location" nearGeoPoint:point withinKilometers:[currentUser[@"distance"] doubleValue]];
    }
    else
    {
        query.limit = m_nCountOnce;
        query.skip = m_nCurrnetCount;
    }
    
    [query orderByDescending:@"createdAt"];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
    {
        if (bShowLoading) {
            [m_hud setHidden:YES];
        }
        
        if (!error)
        {
            if (m_nCurrnetCount == 0)
            {
                utils.mZappList = [[NSMutableArray alloc] init];
                
                if (objects.count > 0) {
                    [self.mTableView setHidden:NO];
                }
                
                [self removeFooterView];
            }
            
            ZappData *zapp;
            for (PFObject *obj in objects) {
                
                BOOL bDuplicated = NO;
                
                // check whether duplicates
                for (ZappData *zData in utils.mZappList)
                {
                    if ([zData.strId isEqualToString:obj.objectId]) {
                        bDuplicated = YES;
                        break;
                    }
                }
                
                if (bDuplicated) {
                    continue;
                }

                zapp = [[ZappData alloc] initWithZapp:obj];
                
                [self getLikeCommentInfo:zapp];
                
                [utils.mZappList addObject:zapp];
            }
            
            [self.mTableView reloadData];
            
            [self finishReloadingData];

            if (![currentUser[@"distanceFilter"] boolValue])
            {
                m_nCurrnetCount += objects.count;
//                if (!(m_nCurrnetCount == 0 && objects.count < m_nCountOnce))
                if (m_nCurrnetCount >= m_nCountOnce)
                {
                    [self setFooterView];
                }
            }
            
            [self createHeaderView];
        }
    }];
    
    if (bShowLoading)
    {
        if (!m_hud || [m_hud isHidden])
        {
            m_hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        }
    }
    
    utils.mbNeedRefresh = NO;
}


# pragma mark - UpdateLikeCommentDelegate
- (void)updateZappInfo:(ZappData *)data
{
    CommonUtils *utils = [CommonUtils sharedObject];
    ZappData *zappdata = [utils.mZappList objectAtIndex:m_nCurZappNum];
    zappdata.bLiked = data.bLiked;
    zappdata.nLikeCount = data.nLikeCount;
    zappdata.nCommentCount = data.nCommentCount;
    
    [self.mTableView reloadData];
}



//＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝
//初始化刷新视图
//＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝
#pragma mark
#pragma methods for creating and removing the header view

-(void)createHeaderView{
    if (_refreshHeaderView && [_refreshHeaderView superview]) {
        [_refreshHeaderView removeFromSuperview];
    }
	_refreshHeaderView = [[EGORefreshTableHeaderView alloc] initWithFrame:
                          CGRectMake(0.0f, 0.0f - self.view.bounds.size.height,
									 self.view.frame.size.width, self.view.bounds.size.height)];
    _refreshHeaderView.delegate = self;
    
    [self.mTableView addSubview:_refreshHeaderView];
    
    [_refreshHeaderView refreshLastUpdatedDate];
}

-(void)removeHeaderView{
    if (_refreshHeaderView && [_refreshHeaderView superview]) {
        [_refreshHeaderView removeFromSuperview];
    }
    _refreshHeaderView = nil;
}

-(void)setFooterView
{
    //    UIEdgeInsets test = self.m_chartView.m_scrollView.contentInset;
    // if the footerView is nil, then create it, reset the position of the footer
    CGFloat height = MAX(self.mTableView.contentSize.height, self.mTableView.frame.size.height);
    
    if (_refreshFooterView && [_refreshFooterView superview]) {
        // reset position
        _refreshFooterView.frame = CGRectMake(0.0f,
                                              height,
                                              self.mTableView.frame.size.width,
                                              self.view.bounds.size.height);
    }else {
        // create the footerView
        _refreshFooterView = [[EGORefreshTableFooterView alloc] initWithFrame:
                              CGRectMake(0.0f, height,
                                         self.mTableView.frame.size.width, self.view.bounds.size.height)];
        _refreshFooterView.delegate = self;
        [self.mTableView addSubview:_refreshFooterView];
    }
    
    if (_refreshFooterView) {
        [_refreshFooterView refreshLastUpdatedDate];
    }
}

-(void)removeFooterView{
    if (_refreshFooterView && [_refreshFooterView superview]) {
        [_refreshFooterView removeFromSuperview];
    }
    _refreshFooterView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

#pragma mark-
#pragma mark force to show the refresh headerView
-(void)showRefreshHeader:(BOOL)animated{
	if (animated)
	{
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:0.2];
		self.mTableView.contentInset = UIEdgeInsetsMake(60.0f, 0.0f, 0.0f, 0.0f);
        // scroll the table view to the top region
        [self.mTableView scrollRectToVisible:CGRectMake(0, 0.0f, 1, 1) animated:NO];
        [UIView commitAnimations];
	}
	else
	{
        self.mTableView.contentInset = UIEdgeInsetsMake(60.0f, 0.0f, 0.0f, 0.0f);
		[self.mTableView scrollRectToVisible:CGRectMake(0, 0.0f, 1, 1) animated:NO];
	}
    
    [_refreshHeaderView setState:EGOOPullRefreshLoading];
}

#pragma mark -
#pragma mark UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
	
	//	NSLog(@"scrollViewDidScroll");
	
	if (_refreshHeaderView) {
        [_refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
    }
	
	if (_refreshFooterView) {
        [_refreshFooterView egoRefreshScrollViewDidScroll:scrollView];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
	
    //	NSLog(@"scrollViewDidEndDragging");
	
	if (_refreshHeaderView) {
        [_refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
    }
	
	if (_refreshFooterView) {
        [_refreshFooterView egoRefreshScrollViewDidEndDragging:scrollView];
    }
}

//===============
//刷新delegate
#pragma mark -
#pragma mark data reloading methods that must be overide by the subclass

-(void)beginToReloadData:(EGORefreshPos)aRefreshPos{
	
	//  should be calling your tableviews data source model to reload
	_reloading = YES;
    
    if (aRefreshPos == EGORefreshHeader) {
        // pull down to refresh data
        [self performSelector:@selector(refreshView) withObject:nil afterDelay:0.0];
    }else if(aRefreshPos == EGORefreshFooter){
        // pull up to load more data
        [self performSelector:@selector(getNextPageView) withObject:nil afterDelay:0.0];
    }
	
	// overide, the actual loading data operation is done in the subclass
}

#pragma mark -
#pragma mark method that should be called when the refreshing is finished
- (void)finishReloadingData{
	
    //	NSLog(@"finishReloadingData");
	
	//  model should call this when its done loading
	_reloading = NO;
    
	if (_refreshHeaderView) {
        [_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.mTableView];
    }
    
    if (_refreshFooterView) {
        [_refreshFooterView egoRefreshScrollViewDataSourceDidFinishedLoading:self.mTableView];
//        [self setFooterView];
    }
    
    // overide, the actula reloading tableView operation and reseting position operation is done in the subclass
}


#pragma mark -
#pragma mark EGORefreshTableDelegate Methods

- (void)egoRefreshTableDidTriggerRefresh:(EGORefreshPos)aRefreshPos{
	
	NSLog(@"egoRefreshTableDidTriggerRefresh");
	
	[self beginToReloadData:aRefreshPos];
	
}

- (BOOL)egoRefreshTableDataSourceIsLoading:(UIView*)view{
	
	return _reloading; // should return if data source model is reloading
	
}


// if we don't realize this method, it won't display the refresh timestamp
- (NSDate*)egoRefreshTableDataSourceLastUpdated:(UIView*)view{
	
	NSLog(@"egoRefreshTableDataSourceLastUpdated");
	
	return [NSDate date]; // should return date data source was last changed
	
}

//刷新调用的方法
-(void)refreshView{
    //    DataAccess *dataAccess= [[DataAccess alloc]init];
    //    NSMutableArray *dataArray = [dataAccess getDateArray];
    //    [self.aoView refreshView:dataArray];
    
    m_nCurrnetCount = 0;
    
    [self getBlog:NO];
    
    //    [self testFinishedLoadData];
	
}
//加载调用的方法
-(void)getNextPageView
{
    [self getBlog:NO];
	
    //    [self testFinishedLoadData];
	
}

-(void)testFinishedLoadData{
    [self finishReloadingData];
    [self createHeaderView];
    [self setFooterView];
}


@end

