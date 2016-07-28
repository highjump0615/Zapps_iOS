//
//  ProfileViewController.m
//  Zapp
//
//  Created by highjump on 14-7-10.
//  Copyright (c) 2014年 Tian. All rights reserved.
//

#import "ProfileViewController.h"
#import "HomeFeedCell.h"

#import <MessageUI/MFMailComposeViewController.h>
#import "ProfileViewController.h"
#import "ProfileSettingViewController.h"
#import "CommentViewController.h"
#import "MBProgressHUD.h"
#import "ShareView.h"

#import "EGORefreshTableHeaderView.h"
#import "EGORefreshTableFooterView.h"


@interface ProfileViewController () <MFMailComposeViewControllerDelegate, BackToRootDelegate, UpdateLikeCommentDelegate, EGORefreshTableDelegate, HideDelegate>
{
    int m_nMode;
    
    int m_nShareHideYPos;
    int m_nShareShowYPos;
    
    int m_nCurrnetMineCount;
    int m_nCurrnetLikedCount;
    int m_nCountOnce;
    
    int m_nMineCount;
    int m_nLikedCount;
    
    NSMutableArray *mMineZapps;
    NSMutableArray *mLikedZapps;
    
    int m_nCurZappNum;
    
    BOOL m_bReady;
    
    //EGOHeader
    EGORefreshTableHeaderView *_refreshHeaderView;
    //EGOFoot
    EGORefreshTableFooterView *_refreshFooterView;
    //
    BOOL _reloading;
    
    NSTimer*	m_timer;
}

@property (weak, nonatomic) IBOutlet UIButton *mButMine;
@property (weak, nonatomic) IBOutlet UIButton *mButLiked;

@property (weak, nonatomic) IBOutlet UIScrollView *mScrollPortrait;
@property (weak, nonatomic) IBOutlet UIPageControl *mPageControl;

@property (weak, nonatomic) IBOutlet UITableView *mTableView;
@property (weak, nonatomic) IBOutlet UIView *mViewPopupMask;
@property (weak, nonatomic) IBOutlet ShareView *mViewShare;

@property (weak, nonatomic) IBOutlet UIButton *mButSetting;
@property (weak, nonatomic) IBOutlet UILabel *mLblTitle;

@property (weak, nonatomic) IBOutlet PFImageView *mImgPhoto;
@property (weak, nonatomic) IBOutlet PFImageView *mImgPhoto1;
@property (weak, nonatomic) IBOutlet PFImageView *mImgPhoto2;
@property (weak, nonatomic) IBOutlet PFImageView *mImgPhoto3;
@property (weak, nonatomic) IBOutlet PFImageView *mImgPhoto4;

@property (weak, nonatomic) IBOutlet UILabel *mLblMineCount;
@property (weak, nonatomic) IBOutlet UILabel *mLblLikedCount;

@property (weak, nonatomic) IBOutlet UIView *mViewHeader;
@property (weak, nonatomic) IBOutlet UIView *mViewButton;

@property (weak, nonatomic) IBOutlet UIScrollView *mScrollContent;

@end

@implementation ProfileViewController

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
    
    [self.mLblTitle setText:@"Profile"];
    
    m_nMode = 0;    // 0: Mine, 1: Liked
    
    m_nShareHideYPos = self.view.frame.size.height + 3;
    m_nShareShowYPos = m_nShareHideYPos - self.mViewShare.frame.size.height;
    
    // shadow on share panel
    [self.mViewShare showShadow];
    self.mViewShare.delegate = self;
    
    [self.mViewShare setFrame:CGRectMake(0, m_nShareHideYPos, self.mViewShare.frame.size.width, self.mViewShare.frame.size.height)];

    if (self.mUser != [PFUser currentUser])
    {
        [self.mButSetting setHidden:YES];
    }
    
    self.mPageControl.currentPage = 0;
    self.mPageControl.numberOfPages = 0;
    
    [self.mScrollPortrait setContentSize:CGSizeMake(self.mScrollPortrait.frame.size.width, 1)];

    [self updateUserInfo];
    
    m_nCountOnce = 5;
    
    mMineZapps = [[NSMutableArray alloc] init];
    mLikedZapps = [[NSMutableArray alloc] init];

    m_nCurrnetMineCount = 0;
    m_nCurrnetLikedCount = 0;
    [self getMineBlog];
    [self getLikedBlog];
    
    m_timer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(onProfilePhotoTimer) userInfo:nil repeats:YES];
    
    m_nLikedCount = m_nMineCount = 0;
    
    self.mViewHeader.opaque = NO;
    self.mViewHeader.backgroundColor = [UIColor clearColor];
    
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:self.mViewHeader.bounds];
    toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    toolbar.barTintColor = [UIColor colorWithRed:149/255.0 green:134/255.0 blue:164/255.0 alpha:1];
    [self.mViewHeader insertSubview:toolbar atIndex:0];
    
    self.mViewButton.opaque = NO;
    toolbar = [[UIToolbar alloc] initWithFrame:self.mViewButton.bounds];
    toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    toolbar.barTintColor = [UIColor colorWithRed:251/255.0 green:250/255.0 blue:248/255.0 alpha:1];
    [self.mViewButton insertSubview:toolbar atIndex:0];
}

- (void)onProfilePhotoTimer
{
	CGPoint pt = [self.mScrollPortrait contentOffset];
    
    pt.x += 320;
    if (pt.x >= 320 * self.mPageControl.numberOfPages)
        pt.x = 0;
	
	[self.mScrollPortrait setContentOffset:pt animated:YES];
    //	[self loadVisiblePages];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    if (m_bReady)
    {
        // get mine and liked count
        m_nMineCount = [self.mUser[@"zappcount"] intValue];
        [self updateLikeMineCount:NO];
        
        PFQuery *queryCount = [PFQuery queryWithClassName:@"Likes"];
        [queryCount whereKey:@"user" equalTo:self.mUser];
        [queryCount findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
         {
             m_nLikedCount = (int)objects.count;
             [self updateLikeMineCount:NO];
         }];
        
        [self setMode:m_nMode];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    CommonUtils *utils = [CommonUtils sharedObject];
    [utils stopCurrentPlaying];
}



#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([[segue identifier] isEqualToString:@"Profile2ProfileSetting"])
    {
        ProfileSettingViewController* settingViewController = [segue destinationViewController];
        settingViewController.delegate = self;
    }
    else if ([[segue identifier] isEqualToString:@"Profile2Profile"])
    {
        ProfileViewController* profileView = [segue destinationViewController];
        ZappData *zapp = [self getZapp:m_nCurZappNum];
        profileView.mUser = zapp.user;
    }
    else if ([[segue identifier] isEqualToString:@"Profile2Comment"])
    {
        CommentViewController* commentViewController = [segue destinationViewController];
        commentViewController.mZappData = [self getZapp:m_nCurZappNum];
        commentViewController.delegate = self;
    }
}


- (void)setButtonImage
{
    if (m_nMode == 0)   // mine
    {
        [self.mButMine setImage:[UIImage imageNamed:@"profile_mine_on_but.png"] forState:UIControlStateNormal];
        [self.mButLiked setImage:[UIImage imageNamed:@"profile_liked_off_but.png"] forState:UIControlStateNormal];
    }
    else if (m_nMode == 1)  // liked
    {
        [self.mButMine setImage:[UIImage imageNamed:@"profile_mine_off_but.png"] forState:UIControlStateNormal];
        [self.mButLiked setImage:[UIImage imageNamed:@"profile_liked_on_but.png"] forState:UIControlStateNormal];
    }
}

- (IBAction)onBack:(id)sender {
    [[self navigationController] popViewControllerAnimated:YES];
}


- (void)setMode:(int)nMode
{
    // stop current play
    CommonUtils *utils = [CommonUtils sharedObject];
    [utils stopCurrentPlaying];
    
    m_nMode = nMode;
    
    [self setButtonImage];
    
    if (m_nMode == 0)
    {
        for (ZappData *zapp in mMineZapps)
        {
            [self getLikeCommentInfo:zapp];
        }
    }
    else
    {
        for (ZappData *zapp in mLikedZapps)
        {
            [self getLikeCommentInfo:zapp];
        }
    }
    
    [self updateTable];
    
    [self setFooter];
}

- (void)setFooter
{
    int nCurCount;
    if (m_nMode == 0)   // like
        nCurCount = m_nCurrnetMineCount;
    else
        nCurCount = m_nCurrnetLikedCount;

    [self removeFooterView];

    if (nCurCount >= m_nCountOnce)
    {
//        [self testFinishedLoadData];
        [self finishReloadingData];
        [self setFooterView];
        [self createHeaderView];
    }
}

- (IBAction)onButMine:(id)sender
{
    [self setMode:0];
}

- (IBAction)onButLiked:(id)sender
{
    [self setMode:1];
}

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
    int nRes = 0;
    
    if (m_nMode == 0)
    {
        nRes = (int)mMineZapps.count;
    }
    else
    {
        nRes = (int)mLikedZapps.count;
    }
    
    return nRes;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HomeFeedCell *feedCell = (HomeFeedCell *)[tableView dequeueReusableCellWithIdentifier:@"ProfileListCell"];
    
    ZappData *zapp = [self getZapp:(int)indexPath.row];
    [feedCell fillContent:zapp];
    
    [feedCell.mButLike addTarget:self action:@selector(onBtnLike:) forControlEvents:UIControlEventTouchUpInside];
    feedCell.mButLike.tag = indexPath.row;
    
    [feedCell.mButUser addTarget:self action:@selector(onBtnUserPhoto:) forControlEvents:UIControlEventTouchUpInside];
    feedCell.mButUser.tag = indexPath.row;
    
    // comment button
    [feedCell.mButComment addTarget:self action:@selector(onBtnComment:) forControlEvents:UIControlEventTouchUpInside];
    feedCell.mButComment.tag = indexPath.row;

    if (feedCell.mnMode != !m_nMode)
    {
        [feedCell swipeMenu];
        
        if (self.mUser == [PFUser currentUser])
        {
            feedCell.mnMode = !m_nMode;
        }
    }
    
    [feedCell.mButDelete setEnabled:feedCell.mnMode];
    
    [feedCell.mButReport addTarget:self action:@selector(onListReport:) forControlEvents:UIControlEventTouchUpInside];
    
    [feedCell.mButDelete addTarget:self action:@selector(onListDelete:) forControlEvents:UIControlEventTouchUpInside];
    feedCell.mButDelete.tag = indexPath.row;
    
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
    ZappData *zapp = [self getZapp:(int)indexPath.row];
    
    nHeight = [CommonUtils getHeight:zapp.strDescription fontsize:13 width:241 height:0] + TEXT_FACTOR;
    
    return nHeight;
}




- (ZappData *)getZapp:(int)nIndex
{
    ZappData *zapp;
    
    if (m_nMode == 0 && mMineZapps.count > 0)   // mine
    {
        zapp = [mMineZapps objectAtIndex:nIndex];
    }
    else if (m_nMode == 1 && mLikedZapps.count > 0)
    {
        zapp = [mLikedZapps objectAtIndex:nIndex];
    }
    
    return zapp;
}

- (void)onBtnUserPhoto:(id)sender
{
    m_nCurZappNum = (int)((UIButton*)sender).tag;
    
    ZappData *zapp = [self getZapp:m_nCurZappNum];
    if ([zapp.user.objectId isEqualToString:[PFUser currentUser].objectId])
    {
        return;
    }
    
    if ([zapp.user.objectId isEqualToString:self.mUser.objectId])
    {
        return;
    }
    
    [self performSegueWithIdentifier:@"Profile2Profile" sender:nil];
}


- (void)onBtnLike:(id)sender
{
    if (self.mUser != [PFUser currentUser])
    {
        return;
    }
    
    if (sender)
    {
        m_nCurZappNum = (int)((UIButton*)sender).tag;
    }
    
    ZappData *zapp = [self getZapp:m_nCurZappNum];
    
    if (zapp.bLiked)
    {
        [mLikedZapps insertObject:zapp atIndex:0];
        m_nCurrnetLikedCount = (int)mLikedZapps.count;
        
        m_nLikedCount++;
        [self updateLikeMineCount:NO];
    }
    else
    {
        [mLikedZapps removeObject:zapp];
        m_nCurrnetLikedCount = (int)mLikedZapps.count;
        
        m_nLikedCount--;
        [self updateLikeMineCount:NO];
    }
    
    [self.mTableView reloadData];
}

- (void)onBtnComment:(id)sender {
    m_nCurZappNum = (int)((UIButton*)sender).tag;
    [self performSegueWithIdentifier:@"Profile2Comment" sender:nil];
}

- (void)onListReport:(id)sender
{
    CommonUtils *utils = [CommonUtils sharedObject];
    [utils reportEmail:self];
    
}

- (void)onListDelete:(id)sender
{
    m_nCurZappNum = (int)((UIButton*)sender).tag;
    
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Delete"
                                                   message:@"Do you really want to delete this zapp?"
                                                  delegate:self
                                         cancelButtonTitle:@"No"
                                         otherButtonTitles:@"Yes",nil];
    [alert show];
}

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == 1)
	{
        ZappData *zappData = [mMineZapps objectAtIndex:m_nCurZappNum];
        CommonUtils *utils = [CommonUtils sharedObject];
        
        // delete comment data
        PFQuery *query = [PFQuery queryWithClassName:@"Comments"];
        [query whereKey:@"zapp" equalTo:zappData.object];
        [query findObjectsInBackgroundWithBlock:^(NSArray *commentobjects, NSError *error)
        {
            if (!error)
            {
                for (PFObject *commentobject in commentobjects)
                {
                    [commentobject deleteInBackground];
                }
            }
            else {
                // Log details of the failure
                NSLog(@"Error: %@ %@", error, [error userInfo]);
            }
        }];
        
        // delete like data
        query = [PFQuery queryWithClassName:@"Likes"];
        [query whereKey:@"zapp" equalTo:zappData.object];
        
        [query findObjectsInBackgroundWithBlock:^(NSArray *likeobjects, NSError *error)
        {
            if (!error)
            {
                for (PFObject *likeobject in likeobjects)
                {
                    [likeobject deleteInBackground];
                }
            }
            else {
                // Log details of the failure
                NSLog(@"Error: %@ %@", error, [error userInfo]);
            }
        }];

        [zappData.object deleteInBackground];
        
        // remove from min list
        [mMineZapps removeObjectAtIndex:m_nCurZappNum];
        m_nCurrnetMineCount--;
        
        m_nMineCount--;
        [self updateLikeMineCount:YES];
        
        // remove from liked list
        ZappData *zData;
        for (zData in mLikedZapps)
        {
            if ([zData.strId isEqualToString:zappData.strId])
            {
                [mLikedZapps removeObject:zData];
                m_nCurrnetLikedCount--;

                m_nLikedCount--;
                [self updateLikeMineCount:NO];
                
                break;
            }
        }

        // remove from main zapp list
        for (zData in utils.mZappList)
        {
            if ([zData.strId isEqualToString:zappData.strId])
            {
                [utils.mZappList removeObject:zData];
                break;
            }
        }

        [self.mTableView reloadData];
    }
}

- (void)onListShare:(id)sender
{
    m_nCurZappNum = (int)((UIButton*)sender).tag;
    ZappData *zapp = [self getZapp:m_nCurZappNum];
    
    [self.mViewShare setZappData:zapp];
    
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

- (void)updateProfilePage
{
    [self.mLblTitle setText:[CommonUtils getUsernameToShow:self.mUser]];
    
    // Set up the page control
    // get the photo data
    int nPhotoCount = 0;
    NSArray *imageViewArray = [NSArray arrayWithObjects:self.mImgPhoto, self.mImgPhoto1, self.mImgPhoto2, self.mImgPhoto3, self.mImgPhoto4, nil];
    
    PFImageView *imageView;
    PFFile *photoFile;
    
    imageView = imageViewArray[nPhotoCount];
    [imageView setImage:[UIImage imageNamed:@"profile_photo_default.png"]];
    if (self.mUser[@"photo"])
    {
        photoFile = self.mUser[@"photo"];
        imageView.file = photoFile;
        [imageView loadInBackground:^(UIImage *image, NSError *error)
        {
            UIImage *imageCropped = [CommonUtils imageWithImage:image
                                                 scaledToHeight:640
                                                          width:640];
            imageView.image = imageCropped;
        }];
        
        nPhotoCount++;
    }
    
    imageView = imageViewArray[nPhotoCount];
    [imageView setImage:[UIImage imageNamed:@"profile_photo_default.png"]];
    if (self.mUser[@"photo1"])
    {
        imageView.file = (PFFile *)self.mUser[@"photo1"];
        [imageView loadInBackground:^(UIImage *image, NSError *error)
        {
            UIImage *imageCropped = [CommonUtils imageWithImage:image
                                                 scaledToHeight:640
                                                          width:640];
            imageView.image = imageCropped;
        }];
        
        nPhotoCount++;
    }
    
    imageView = imageViewArray[nPhotoCount];
    [imageView setImage:[UIImage imageNamed:@"profile_photo_default.png"]];
    if (self.mUser[@"photo2"])
    {
        imageView.file = (PFFile *)self.mUser[@"photo2"];
        [imageView loadInBackground:^(UIImage *image, NSError *error)
        {
            UIImage *imageCropped = [CommonUtils imageWithImage:image
                                                 scaledToHeight:640
                                                          width:640];
            imageView.image = imageCropped;
        }];
        
        nPhotoCount++;
    }
    
    imageView = imageViewArray[nPhotoCount];
    [imageView setImage:[UIImage imageNamed:@"profile_photo_default.png"]];
    if (self.mUser[@"photo3"])
    {
        imageView.file = (PFFile *)self.mUser[@"photo3"];
        [imageView loadInBackground:^(UIImage *image, NSError *error)
        {
            UIImage *imageCropped = [CommonUtils imageWithImage:image
                                                 scaledToHeight:640
                                                          width:640];
            imageView.image = imageCropped;
        }];
        
        nPhotoCount++;
    }
    
    imageView = imageViewArray[nPhotoCount];
    [imageView setImage:[UIImage imageNamed:@"profile_photo_default.png"]];
    if (self.mUser[@"photo4"])
    {
        imageView.file = (PFFile *)self.mUser[@"photo4"];
        [imageView loadInBackground:^(UIImage *image, NSError *error) {
            UIImage *imageCropped = [CommonUtils imageWithImage:image
                                                 scaledToHeight:640
                                                          width:640];
            imageView.image = imageCropped;
        }];
        
        nPhotoCount++;
    }
    
    self.mPageControl.currentPage = 0;
    self.mPageControl.numberOfPages = nPhotoCount;
    
    [self.mScrollPortrait setContentSize:CGSizeMake(self.mScrollPortrait.frame.size.width * nPhotoCount, 1)];
    
//    [self.view setHidden:NO];
}

- (void)updateLikeMineCount:(BOOL)bSave
{
    self.mUser[@"zappcount"] = [NSNumber numberWithInt:m_nMineCount];
    
    [self.mLblMineCount setText:[NSString stringWithFormat:@"%d", m_nMineCount]];
    [self.mLblLikedCount setText:[NSString stringWithFormat:@"%d", m_nLikedCount]];
    
    if (bSave && self.mUser == [PFUser currentUser])
    {
        [self.mUser saveInBackground];
    }
}

#pragma mark BackToRootDelegate
- (void)updateUserInfo
{
    if (!self.mUser.createdAt)   // not feched
    {
        m_bReady = NO;
        
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
//        [self.view setHidden:YES];
        
        [self.mUser fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error)
        {
            [self updateProfilePage];
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            m_bReady = YES;
            
            [self viewDidAppear:NO];
        }];
    }
    else
    {
        m_bReady = YES;
        [self updateProfilePage];
    }
}

- (void) backToRootView
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)getLikeCommentInfo:(ZappData *)zapp
{
    PFUser *currentUser = [PFUser currentUser];
    
    if (!currentUser)
    {
        return;
    }
    
    PFQuery *query = [PFQuery queryWithClassName:@"Likes"];
    [query whereKey:@"zapp" equalTo:zapp.object];
    [query whereKey:@"user" equalTo:currentUser];
    
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

- (void)getLikedBlog
{
    PFQuery *query = [PFQuery queryWithClassName:@"Likes"];
    [query orderByDescending:@"createdAt"];
    [query whereKey:@"user" equalTo:self.mUser];
    [query includeKey:@"zapp"];
    
    query.limit = m_nCountOnce;
    query.skip = m_nCurrnetLikedCount;
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
    {
        if (!error) {
            
            if (m_nCurrnetLikedCount == 0)
            {
                [mLikedZapps removeAllObjects];
                [self setFooter];
            }
            
            if (objects.count > 0)
            {
                //                [self.mNoMediaLbl setHidden:YES];
                
                for (PFObject *obj in objects)
                {
                    ZappData *zapp = [[ZappData alloc] initWithZapp:obj[@"zapp"]];
                    [self getLikeCommentInfo:zapp];
                    [mLikedZapps addObject:zapp];
                }
            }
            
            [self updateTable];
            
            m_nCurrnetLikedCount += objects.count;
            [self setFooter];
        }
        else {
            
            NSString *errorString = [error userInfo][@"error"];
            
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:errorString delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
        
    }];
}

- (void)getMineBlog
{
    PFQuery *query = [PFQuery queryWithClassName:@"Zapps"];
    [query orderByDescending:@"createdAt"];
    [query whereKey:@"user" equalTo:self.mUser];
    
    query.limit = m_nCountOnce;
    query.skip = m_nCurrnetMineCount;

    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        if (!error) {
            //            [MBProgressHUD hideHUDForView:self.view animated:YES];
            //
            //            self.mPostNumLbl.text = [NSString stringWithFormat:@"%lu", (unsigned long)objects.count];
            
            if (m_nCurrnetMineCount == 0)
            {
                [mMineZapps removeAllObjects];
                [self setFooter];
            }
            
            ZappData *zapp;
            
            if (objects.count > 0) {
                //                [self.mNoMediaLbl setHidden:YES];
                
                for (PFObject *obj in objects)
                {
                    zapp = [[ZappData alloc] initWithZapp:obj];
                    
                    [self getLikeCommentInfo:zapp];
                    [mMineZapps addObject:zapp];
                }
            }
            
            [self updateTable];
            
            m_nCurrnetMineCount += objects.count;
            [self setFooter];
        }
        else {
            
            NSString *errorString = [error userInfo][@"error"];
            
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:errorString delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
        
    }];
}

# pragma mark - UpdateLikeCommentDelegate
- (void)updateZappInfo:(ZappData *)data
{
    ZappData *zappdata;
    
    if (m_nMode == 0)   // mine
    {
        zappdata = [mMineZapps objectAtIndex:m_nCurZappNum];
    }
    else
    {
        zappdata = [mLikedZapps objectAtIndex:m_nCurZappNum];
    }
    
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

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	
	//	NSLog(@"scrollViewDidScroll");
    
    if (scrollView == self.mScrollPortrait)
    {
        // First, determine which page is currently visible
        CGFloat pageWidth = self.mScrollPortrait.frame.size.width;
        NSInteger nPage = (NSInteger)floor((self.mScrollPortrait.contentOffset.x * 2.0f + pageWidth) / (pageWidth * 2.0f));
        
        // Update the page control
        self.mPageControl.currentPage = nPage;
        
        // infinite scrolling
        //    if (self.mScrollView.contentOffset.x == 0)
        //    {
        //        [self.mScrollPortrait setContentOffset:CGPointMake(self.mScrollPortrait.frame.size.width * 3, 0)];
        //    }
        //    else if (self.mScrollView.contentOffset.x == self.mScrollView.frame.size.width * 4)
        //    {
        //        [self.mScrollView setContentOffset:CGPointMake(self.mScrollView.frame.size.width * 1, 0)];
        //    }
    }
    else if (scrollView == self.mScrollContent)
    {
        if (scrollView.contentOffset.y >= 0)
        {
            [scrollView setContentOffset:CGPointMake(scrollView.contentOffset.x, 0)];
        }
        else
        {
            int nYOffset = (int)scrollView.frame.origin.y;
            int nHeight = nYOffset - scrollView.contentOffset.y + self.mViewButton.frame.size.height;
            
            if (nHeight > 320)
            {
                int nContentOffset = nYOffset + self.mViewButton.frame.size.height - 320;
                [scrollView setContentOffset:CGPointMake(scrollView.contentOffset.x, nContentOffset)];
                nHeight = 320;
            }
            
            CGRect rect = self.mScrollPortrait.frame;
            rect.size.height = nHeight;
            [self.mScrollPortrait setFrame:rect];
            
            rect = self.mTableView.frame;
            rect.origin.y = nHeight;
            rect.size.height = self.view.frame.size.height - nHeight;
            [self.mTableView setFrame:rect];
            
            rect = self.mPageControl.frame;
            rect.origin.y = nHeight - self.mViewButton.frame.size.height - 35;
            [self.mPageControl setFrame:rect];
        }
    }
    else
    {
        if (_refreshHeaderView) {
            [_refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
        }
        
        if (_refreshFooterView) {
            [_refreshFooterView egoRefreshScrollViewDidScroll:scrollView];
        }
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    //	NSLog(@"scrollViewDidEndDragging");

    if (scrollView == self.mScrollPortrait || scrollView == self.mScrollContent)
    {
        return;
    }
	
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
    
    if (m_nMode == 0)    // mine
    {
        m_nCurrnetMineCount = 0;
        [self getMineBlog];
    }
    else
    {
        m_nCurrnetLikedCount = 0;
        [self getLikedBlog];
    }
    
    //    [self testFinishedLoadData];
	
}

//加载调用的方法
-(void)getNextPageView
{
    if (m_nMode == 0)    // mine
    {
        [self getMineBlog];
    }
    else
    {
        [self getLikedBlog];
    }
	
    //    [self testFinishedLoadData];
	
}

-(void)testFinishedLoadData{
    [self finishReloadingData];
    [self createHeaderView];
    [self setFooterView];
}




@end
