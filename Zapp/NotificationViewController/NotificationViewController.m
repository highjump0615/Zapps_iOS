//
//  NotificationViewController.m
//  Zapp
//
//  Created by highjump on 14-7-12.
//  Copyright (c) 2014年 Tian. All rights reserved.
//

#import "NotificationViewController.h"
#import "ProfileViewController.h"
#import "MBProgressHUD.h"
#import "CommonUtils.h"
#import "NotificationTableViewCell.h"
#import "CommentViewController.h"

#import "EGORefreshTableFooterView.h"

@interface NotificationViewController () <EGORefreshTableDelegate>
{
    NSMutableArray *mLikeNotifyList;
    NSMutableArray *mCommentNotifyList;
    
    int m_nLikeCurCount;
    int m_nCommentCurCount;
    
    int mnNotifyType;
    int m_nCountOnce;
    
    int m_nCurNotifyNum;
    
    //EGOFoot
    EGORefreshTableFooterView *_refreshFooterView;
    BOOL _reloading;
}

@property (weak, nonatomic) IBOutlet UITableView *mTableView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *mSegment;

@end

@implementation NotificationViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)getNotificationData
{
    PFQuery *query;
    
    if (mnNotifyType == 0)  // like
    {
        query = [PFQuery queryWithClassName:@"Likes"];
        [query whereKey:@"targetuser" equalTo:[PFUser currentUser]];
        [query orderByDescending:@"updatedAt"];
        
        query.limit = m_nCountOnce;
        query.skip = m_nLikeCurCount;
        
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
         {
             if (!error)
             {
                 if (m_nLikeCurCount == 0)
                 {
                     [mLikeNotifyList removeAllObjects];
                     [self removeFooterView];
                 }
                 
                 for (PFObject *obj in objects)
                 {
                     NotificationData *notifyData = [[NotificationData alloc] initWithData:obj];
                     notifyData.notificationType = mnNotifyType;
                     [mLikeNotifyList addObject:notifyData];
                 }
                 m_nLikeCurCount += objects.count;
                 
                 [self.mTableView reloadData];
                 
                 if (m_nLikeCurCount > m_nCountOnce)
                 {
                     [self testFinishedLoadData];
                 }
             }
             else
             {
                 NSString *errorString = [error userInfo][@"error"];
                 
                 UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:errorString delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                 [alert show];
             }
         }];
    }
    else    // comment
    {
        query = [PFQuery queryWithClassName:@"Comments"];
        [query whereKey:@"targetuser" equalTo:[PFUser currentUser]];
        [query orderByDescending:@"updatedAt"];
        
        query.limit = m_nCountOnce;
        query.skip = m_nCommentCurCount;
        
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
         {
             if (!error)
             {
                 if (m_nCommentCurCount == 0)
                 {
                     [mCommentNotifyList removeAllObjects];
                     [self removeFooterView];
                 }
                 
                 for (PFObject *obj in objects)
                 {
                     NotificationData *notifyData = [[NotificationData alloc] initWithData:obj];
                     notifyData.notificationType = mnNotifyType;
                     [mCommentNotifyList addObject:notifyData];
                 }
                 m_nCommentCurCount += objects.count;
                 
                 [self.mTableView reloadData];
                 
                 if (m_nCommentCurCount > m_nCountOnce)
                 {
                     [self testFinishedLoadData];
                 }
             }
             else
             {
                 NSString *errorString = [error userInfo][@"error"];
                 
                 UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:errorString delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                 [alert show];
             }
         }];
    }
}

- (void)onChangeSegment:(id)sender forEvent:(UIEvent *)event
{
    mnNotifyType = (int)self.mSegment.selectedSegmentIndex;
    m_nLikeCurCount = m_nCommentCurCount = 0;
    [self getNotificationData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    mLikeNotifyList = [[NSMutableArray alloc] init];
    mCommentNotifyList = [[NSMutableArray alloc] init];
    
    [self.mSegment addTarget:self
                      action:@selector(onChangeSegment:forEvent:)
            forControlEvents:UIControlEventValueChanged];
    
    mnNotifyType = 0;   // like
    m_nLikeCurCount = m_nCommentCurCount = 0;
    m_nCountOnce = 10;
    [self getNotificationData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    CommonUtils *utils = [CommonUtils sharedObject];
    [utils stopCurrentPlaying];
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
    if ([[segue identifier] isEqualToString:@"Notification2Profile"])
    {
        ProfileViewController *profileView = (ProfileViewController *)[segue destinationViewController];
        NotificationData *nd = [self getNotification:m_nCurNotifyNum];
        profileView.mUser = nd.user;
    }
    else if ([[segue identifier] isEqualToString:@"Notification2Comment"])
    {
        CommentViewController *commentView = (CommentViewController *)[segue destinationViewController];
        NotificationData *nd = [self getNotification:m_nCurNotifyNum];
        
        ZappData *zapp = [[ZappData alloc] init];
        
        zapp.strId = nd.zapp.objectId;
        zapp.object = nd.zapp;
        zapp.bLiked = -1;
        
        commentView.mZappData = zapp;
    }
}

- (NotificationData *)getNotification:(int)nIndex
{
    NotificationData *notify;
    
    if (mnNotifyType == 0)   // likw
    {
        notify = [mLikeNotifyList objectAtIndex:nIndex];
    }
    else
    {
        notify = [mCommentNotifyList objectAtIndex:nIndex];
    }
    
    return notify;
}


- (IBAction)onBack:(id)sender {
    [[self navigationController] popViewControllerAnimated:YES];
}


#pragma mark - TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (mnNotifyType == 0)  // like
    {
        return [mLikeNotifyList count];
    }
    else    // comment
    {
        return [mCommentNotifyList count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NotificationTableViewCell *notificationCell = (NotificationTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"NotificationListCell"];
    NotificationData *notifyData;
    
    notifyData = [self getNotification:(int)indexPath.row];
    
    [notificationCell fillContent:notifyData];
    
    [notificationCell.mButUser addTarget:self action:@selector(onBtnUserPhoto:) forControlEvents:UIControlEventTouchUpInside];
    notificationCell.mButUser.tag = indexPath.row;
    
    return notificationCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    m_nCurNotifyNum = (int)indexPath.row;
    [self performSegueWithIdentifier:@"Notification2Comment" sender:nil];
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([tableView.indexPathsForVisibleRows indexOfObject:indexPath] == NSNotFound)
    {
        NotificationTableViewCell *feedCell = (NotificationTableViewCell *)cell;
        [feedCell stopPlaying];
    }
}



- (void)onBtnUserPhoto:(id)sender
{
    m_nCurNotifyNum = (int)((UIButton*)sender).tag;
    
    NotificationData *nd = [self getNotification:m_nCurNotifyNum];
    if ([nd.user.objectId isEqualToString:[PFUser currentUser].objectId])
    {
        return;
    }
    
    [self performSegueWithIdentifier:@"Notification2Profile" sender:nil];
}


-(void)setFooterView{
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

#pragma mark -
#pragma mark UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
	
	//	NSLog(@"scrollViewDidScroll");
	
	if (_refreshFooterView) {
        [_refreshFooterView egoRefreshScrollViewDidScroll:scrollView];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
	
    //	NSLog(@"scrollViewDidEndDragging");
	
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
    
    if (_refreshFooterView) {
        [_refreshFooterView egoRefreshScrollViewDataSourceDidFinishedLoading:self.mTableView];
        [self setFooterView];
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
    
    //    m_nCurrnetCount = 0;
    
    //    [self getBlog:NO];
    
    //    [self testFinishedLoadData];
	
}
//加载调用的方法
-(void)getNextPageView{
    
    [self getNotificationData];
    //    [self testFinishedLoadData];
	
}

-(void)testFinishedLoadData{
    [self finishReloadingData];
    [self setFooterView];
}


@end
