//
//  ProfileSettingViewController.m
//  Zapp
//
//  Created by highjump on 14-7-11.
//  Copyright (c) 2014年 Tian. All rights reserved.
//

#import "ProfileSettingViewController.h"
#import "MBProgressHUD.h"
#import "CommonUtils.h"

@interface ProfileSettingViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>
{
    BOOL mbPhoto1;
    BOOL mbPhoto2;
    BOOL mbPhoto3;
    BOOL mbPhoto4;
    
    BOOL mbPhotoUploaded;
    BOOL mbPhotoThumbUploaded;
    BOOL mbPhotoUploaded1;
    BOOL mbPhotoUploaded2;
    BOOL mbPhotoUploaded3;
    BOOL mbPhotoUploaded4;
    
    BOOL mbPhotoChanged;
    BOOL mbPhotoChanged1;
    BOOL mbPhotoChanged2;
    BOOL mbPhotoChanged3;
    BOOL mbPhotoChanged4;
    
    UIImagePickerController *mPickerPhoto;
    UIImagePickerController *mPickerPhoto1;
    UIImagePickerController *mPickerPhoto2;
    UIImagePickerController *mPickerPhoto3;
    UIImagePickerController *mPickerPhoto4;
    
    int mnHeightOffset;
    
    NSTimer* mSavePhotoTimer;
    NSString *mStrOldName;
    
    BOOL mbDistanceFilterOld;
    int mnDistanceOld;
}

@property (weak, nonatomic) IBOutlet UIScrollView *mScrollView;

@property (weak, nonatomic) IBOutlet UIButton *mBtnPhoto;
@property (weak, nonatomic) IBOutlet UIButton *mBtnPhoto1;
@property (weak, nonatomic) IBOutlet UIButton *mBtnPhoto2;
@property (weak, nonatomic) IBOutlet UIButton *mBtnPhoto3;
@property (weak, nonatomic) IBOutlet UIButton *mBtnPhoto4;

@property (weak, nonatomic) IBOutlet UIButton *mBtnDeletePhoto;
@property (weak, nonatomic) IBOutlet UIButton *mBtnDeletePhoto1;
@property (weak, nonatomic) IBOutlet UIButton *mBtnDeletePhoto2;
@property (weak, nonatomic) IBOutlet UIButton *mBtnDeletePhoto3;
@property (weak, nonatomic) IBOutlet UIButton *mBtnDeletePhoto4;

@property (weak, nonatomic) IBOutlet UITextField *mTxtNickname;

@property (weak, nonatomic) IBOutlet UISwitch *mSwitchDistance;

@property (weak, nonatomic) IBOutlet UILabel *mLblDistanceTitle;
@property (weak, nonatomic) IBOutlet UISlider *mSliderDistance;
@property (weak, nonatomic) IBOutlet UILabel *mLblDistance;
@property (weak, nonatomic) IBOutlet UILabel *mLblDistanceMin;
@property (weak, nonatomic) IBOutlet UILabel *mLblDistanceMax;

@property (weak, nonatomic) IBOutlet UIView *mViewPassword;
@property (weak, nonatomic) IBOutlet UITextField *mTxtPassword;
@property (weak, nonatomic) IBOutlet UITextField *mTxtConfirmPassword;

@end

@implementation ProfileSettingViewController

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
    
    [self.mScrollView setContentSize:CGSizeMake(self.mScrollView.frame.size.width, 540)];
    
    [self.mBtnDeletePhoto.layer setCornerRadius:15.0];
    [self.mBtnDeletePhoto1.layer setCornerRadius:15.0];
    [self.mBtnDeletePhoto2.layer setCornerRadius:15.0];
    [self.mBtnDeletePhoto3.layer setCornerRadius:15.0];
    [self.mBtnDeletePhoto4.layer setCornerRadius:15.0];
    
    [self.mBtnDeletePhoto setHidden:YES];
    
    [self showDeletePhotoButtons];
    
    // image picker
    mPickerPhoto = [[UIImagePickerController alloc] init];
    mPickerPhoto.delegate = self;
    mPickerPhoto.allowsEditing = YES;
    mPickerPhoto.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    mPickerPhoto1 = [[UIImagePickerController alloc] init];
    mPickerPhoto1.delegate = self;
    mPickerPhoto1.allowsEditing = YES;
    mPickerPhoto1.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    mPickerPhoto2 = [[UIImagePickerController alloc] init];
    mPickerPhoto2.delegate = self;
    mPickerPhoto2.allowsEditing = YES;
    mPickerPhoto2.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;

    mPickerPhoto3 = [[UIImagePickerController alloc] init];
    mPickerPhoto3.delegate = self;
    mPickerPhoto3.allowsEditing = YES;
    mPickerPhoto3.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;

    mPickerPhoto4 = [[UIImagePickerController alloc] init];
    mPickerPhoto4.delegate = self;
    mPickerPhoto4.allowsEditing = YES;
    mPickerPhoto4.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillShow:)
												 name:UIKeyboardWillShowNotification
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillHide:)
												 name:UIKeyboardWillHideNotification
											   object:nil];

    //
    // show user Info
    //
    PFUser *currentUser = [PFUser currentUser];
    
    // photo
    if (currentUser[@"photo"])
    {
        PFImageView *imageView = [[PFImageView alloc] init];
        imageView.image = [UIImage imageNamed:@"psetting_no_pic_but.png"];
        imageView.file = currentUser[@"photo"];
        [imageView loadInBackground:^(UIImage *image, NSError *error) {
            [self.mBtnPhoto setImage:image forState:UIControlStateNormal];
        }];
    }
    
    if (currentUser[@"photo1"])
    {
        PFImageView *imageView1 = [[PFImageView alloc] init];
        imageView1.image = [UIImage imageNamed:@"psetting_no_pic_but.png"];
        imageView1.file = currentUser[@"photo1"];
        [imageView1 loadInBackground:^(UIImage *image, NSError *error) {
            [self.mBtnPhoto1 setImage:image forState:UIControlStateNormal];
        }];
        mbPhoto1 = YES;
    }
    
    if (currentUser[@"photo2"])
    {
        PFImageView *imageView2 = [[PFImageView alloc] init];
        imageView2.image = [UIImage imageNamed:@"psetting_no_pic_but.png"];
        imageView2.file = currentUser[@"photo2"];
        [imageView2 loadInBackground:^(UIImage *image, NSError *error) {
            [self.mBtnPhoto2 setImage:image forState:UIControlStateNormal];
        }];
        mbPhoto2 = YES;
    }
    
    if (currentUser[@"photo3"])
    {
        PFImageView *imageView3 = [[PFImageView alloc] init];
        imageView3.image = [UIImage imageNamed:@"psetting_no_pic_but.png"];
        imageView3.file = currentUser[@"photo3"];
        [imageView3 loadInBackground:^(UIImage *image, NSError *error) {
            [self.mBtnPhoto3 setImage:image forState:UIControlStateNormal];
        }];
        mbPhoto3 = YES;
    }
    
    if (currentUser[@"photo4"])
    {
        PFImageView *imageView4 = [[PFImageView alloc] init];
        imageView4.image = [UIImage imageNamed:@"psetting_no_pic_but.png"];
        imageView4.file = currentUser[@"photo4"];
        [imageView4 loadInBackground:^(UIImage *image, NSError *error) {
            [self.mBtnPhoto4 setImage:image forState:UIControlStateNormal];
        }];
        mbPhoto4 = YES;
    }
    [self showDeletePhotoButtons];
    
    mbPhotoChanged = mbPhotoChanged1 = mbPhotoChanged2 = mbPhotoChanged3 = mbPhotoChanged4 = NO;
    
    // show full name
    mStrOldName = currentUser[@"fullname"];
    [self.mTxtNickname setText:currentUser[@"fullname"]];
    
    // show distance
    [self.mSliderDistance setValue:[currentUser[@"distance"] intValue]];
    [self.mLblDistance setText:[NSString stringWithFormat:@"%dKM", [currentUser[@"distance"] intValue]]];
    
    mSavePhotoTimer = nil;
    mbPhotoUploaded = mbPhotoThumbUploaded = mbPhotoUploaded1 = mbPhotoUploaded2 = mbPhotoUploaded3 = mbPhotoUploaded4 = YES;
    
    // distance enable state
    mbDistanceFilterOld = [currentUser[@"distanceFilter"] boolValue];
    mnDistanceOld = [currentUser[@"distance"] intValue];
    
    [self.mSwitchDistance setOn:[currentUser[@"distanceFilter"] boolValue]];
    [self enableDistanceView];
}

-(void)dismissKeyboard {
    [self.view endEditing:YES];
}

- (void)showDeletePhotoButtons
{
    [self.mBtnDeletePhoto1 setHidden:!mbPhoto1];
    [self.mBtnDeletePhoto2 setHidden:!mbPhoto2];
    [self.mBtnDeletePhoto3 setHidden:!mbPhoto3];
    [self.mBtnDeletePhoto4 setHidden:!mbPhoto4];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)onCancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onSave:(id)sender
{
    PFUser *currentUser = [PFUser currentUser];
    
    if (!currentUser)
        return;
    
    // check whether password matches or not
    if (self.mTxtPassword.text.length > 0 || self.mTxtConfirmPassword.text.length > 0)
    {
        if (![self.mTxtPassword.text isEqualToString:self.mTxtConfirmPassword.text])
        {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"Password does not match" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            return;
        }
    }
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    //
    // save photo data
    //
//    UIImage *imagePhoto;
    UIImage *image;
    NSData *dataPhoto;
    PFFile *imageFile;
    
    if (mbPhotoChanged)
    {
        image = self.mBtnPhoto.imageView.image;
//        imagePhoto = [CommonUtils imageWithImage:image scaledToSize:CGSizeMake(290, 290)];
        dataPhoto = UIImageJPEGRepresentation(image, 10);
        
        imageFile = [PFFile fileWithName:@"photo.jpg" data:dataPhoto];
        mbPhotoUploaded = NO;
        [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            mbPhotoUploaded = succeeded;
            if (!mbPhotoUploaded)
            {
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"Failed saving photos" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
            }
        }];
        currentUser[@"photo"] = imageFile;
        
        UIImage *imagePhotoThumb = [CommonUtils imageWithImage:image scaledToSize:CGSizeMake(80, 80)];
        NSData *dataPhotoThumb = UIImageJPEGRepresentation(imagePhotoThumb, 10);
        PFFile *imageFileThumb = [PFFile fileWithName:@"photoThumb.jpg" data:dataPhotoThumb];
        mbPhotoThumbUploaded = NO;
        [imageFileThumb saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            mbPhotoThumbUploaded = succeeded;
            if (!mbPhotoThumbUploaded)
            {
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"Failed saving photos" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
            }
        }];
        currentUser[@"photothumb"] = imageFileThumb;
    }
    
    if (mbPhotoChanged1)
    {
        image = self.mBtnPhoto1.imageView.image;
//        imagePhoto = [CommonUtils imageWithImage:image scaledToSize:CGSizeMake(290, 290)];
        dataPhoto = UIImageJPEGRepresentation(image, 10);
        
        imageFile = [PFFile fileWithName:@"photo1.jpg" data:dataPhoto];
        mbPhotoUploaded1 = NO;
        [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            mbPhotoUploaded1 =succeeded;
            if (!mbPhotoUploaded1)
            {
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"Failed saving photos" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
            }
        }];
        currentUser[@"photo1"] = imageFile;
    }
    
    if (mbPhotoChanged2)
    {
        image = self.mBtnPhoto2.imageView.image;
//        imagePhoto = [CommonUtils imageWithImage:image scaledToSize:CGSizeMake(290, 290)];
        dataPhoto = UIImageJPEGRepresentation(image, 10);
        
        imageFile = [PFFile fileWithName:@"photo2.jpg" data:dataPhoto];
        mbPhotoUploaded2 = NO;
        [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            mbPhotoUploaded2 = succeeded;
            if (!mbPhotoUploaded2)
            {
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"Failed saving photos" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
            }

        }];
        currentUser[@"photo2"] = imageFile;
    }
    
    if (mbPhotoChanged3)
    {
        image = self.mBtnPhoto3.imageView.image;
//        imagePhoto = [CommonUtils imageWithImage:image scaledToSize:CGSizeMake(290, 290)];
        dataPhoto = UIImageJPEGRepresentation(image, 10);
        
        imageFile = [PFFile fileWithName:@"photo3.jpg" data:dataPhoto];
        mbPhotoUploaded3 = NO;
        [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            mbPhotoUploaded3 = succeeded;
            if (!mbPhotoUploaded3)
            {
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"Failed saving photos" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
            }
        }];
        currentUser[@"photo3"] = imageFile;
    }
    
    if (mbPhotoChanged4)
    {
        image = self.mBtnPhoto4.imageView.image;
//        imagePhoto = [CommonUtils imageWithImage:image scaledToSize:CGSizeMake(290, 290)];
        dataPhoto = UIImageJPEGRepresentation(image, 10);
        
        imageFile = [PFFile fileWithName:@"photo4.jpg" data:dataPhoto];
        mbPhotoUploaded4 = NO;
        [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            mbPhotoUploaded4 = succeeded;
            if (!mbPhotoUploaded4)
            {
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"Failed saving photos" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
            }
        }];
        currentUser[@"photo4"] = imageFile;
    }
    
    if (!mbPhoto1 && currentUser[@"photo1"])
    {
        [currentUser removeObjectForKey:@"photo1"];
    }
    if (!mbPhoto2 && currentUser[@"photo2"])
    {
        [currentUser removeObjectForKey:@"photo2"];
    }
    if (!mbPhoto3 && currentUser[@"photo3"])
    {
        [currentUser removeObjectForKey:@"photo3"];
    }
    if (!mbPhoto4 && currentUser[@"photo4"])
    {
        [currentUser removeObjectForKey:@"photo4"];
    }
    
    // save full name
    currentUser[@"fullname"] = self.mTxtNickname.text;
    
    // save distance
    currentUser[@"distanceFilter"] = [NSNumber numberWithBool:self.mSwitchDistance.on];
    currentUser[@"distance"] = [NSNumber numberWithInteger:(int)self.mSliderDistance.value];
    
    if (mbDistanceFilterOld != self.mSwitchDistance.on ||
        mnDistanceOld != (int)self.mSliderDistance.value)
    {
        CommonUtils *utils = [CommonUtils sharedObject];
        utils.mbNeedRefresh = YES;
    }
    
    // save password
    currentUser.password = self.mTxtPassword.text;
    
    mSavePhotoTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(checkSavePhotoThread:) userInfo:nil repeats:YES];
    
    [hud setLabelText:@"Saving..."];
}

- (void) checkSavePhotoThread:(NSTimer*)theTimer
{
    if (mbPhotoUploaded && mbPhotoThumbUploaded && mbPhotoUploaded1 && mbPhotoUploaded2 && mbPhotoUploaded3 && mbPhotoUploaded4)
    {
        PFUser *currentUser = [PFUser currentUser];
        
        // update name in zapp, like, comments if changed
        if (![mStrOldName isEqualToString:currentUser[@"fullname"]])
        {
            // zapp
            PFQuery *query = [PFQuery queryWithClassName:@"Zapps"];
            [query whereKey:@"user" equalTo:currentUser];
            
            [query findObjectsInBackgroundWithBlock:^(NSArray *zappobjects, NSError *error)
             {
                 if (!error)
                 {
                     for (PFObject *object in zappobjects)
                     {
                         object[@"username"] = currentUser[@"fullname"];
                         [object saveInBackground];
                     }
                 }
                 else
                 {
                     // Log details of the failure
                     NSLog(@"Error: %@ %@", error, [error userInfo]);
                 }
             }];
            
            // like
            query = [PFQuery queryWithClassName:@"Likes"];
            [query whereKey:@"user" equalTo:currentUser];
            
            [query findObjectsInBackgroundWithBlock:^(NSArray *likeobjects, NSError *error)
            {
                if (!error)
                {
                    for (PFObject *object in likeobjects)
                    {
                        object[@"username"] = currentUser[@"fullname"];
                        [object saveInBackground];
                    }
                }
                else
                {
                    // Log details of the failure
                    NSLog(@"Error: %@ %@", error, [error userInfo]);
                }
            }];
            
            // comment
            query = [PFQuery queryWithClassName:@"Comments"];
            [query whereKey:@"user" equalTo:currentUser];
            
            [query findObjectsInBackgroundWithBlock:^(NSArray *commentobjects, NSError *error)
             {
                 if (!error)
                 {
                     for (PFObject *object in commentobjects)
                     {
                         object[@"username"] = currentUser[@"fullname"];
                         [object saveInBackground];
                     }
                 }
                 else
                 {
                     // Log details of the failure
                     NSLog(@"Error: %@ %@", error, [error userInfo]);
                 }
             }];
        }
        
        
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        
        [[PFUser currentUser] saveInBackground];
        [self.delegate updateUserInfo];
        [self onCancel:nil];
        
        [mSavePhotoTimer invalidate];
        mSavePhotoTimer = nil;
    }
}

- (IBAction)onDeletePhoto1:(id)sender
{
    [self.mBtnPhoto1 setImage:[UIImage imageNamed:@"psetting_no_pic_but.png"] forState:UIControlStateNormal];
    mbPhoto1 = NO;
    mbPhotoChanged1 = NO;
    [self showDeletePhotoButtons];
}

- (IBAction)onDeletePhoto2:(id)sender
{
    [self.mBtnPhoto2 setImage:[UIImage imageNamed:@"psetting_no_pic_but.png"] forState:UIControlStateNormal];
    mbPhoto2 = NO;
    mbPhotoChanged2 = NO;
    [self showDeletePhotoButtons];
}

- (IBAction)onDeletePhoto3:(id)sender
{
    [self.mBtnPhoto3 setImage:[UIImage imageNamed:@"psetting_no_pic_but.png"] forState:UIControlStateNormal];
    mbPhoto3 = NO;
    mbPhotoChanged3 = NO;
    [self showDeletePhotoButtons];
}

- (IBAction)onDeletePhoto4:(id)sender
{
    [self.mBtnPhoto4 setImage:[UIImage imageNamed:@"psetting_no_pic_but.png"] forState:UIControlStateNormal];
    mbPhoto4 = NO;
    mbPhotoChanged4 = NO;
    [self showDeletePhotoButtons];
}

- (IBAction)onButPhoto:(id)sender
{
    [self presentViewController:mPickerPhoto animated:YES completion:NULL];
}

- (IBAction)onButPhoto1:(id)sender
{
    [self presentViewController:mPickerPhoto1 animated:YES completion:NULL];
}

- (IBAction)onButPhoto2:(id)sender
{
    [self presentViewController:mPickerPhoto2 animated:YES completion:NULL];
}

- (IBAction)onButPhoto3:(id)sender
{
    [self presentViewController:mPickerPhoto3 animated:YES completion:NULL];
}

- (IBAction)onButPhoto4:(id)sender
{
    [self presentViewController:mPickerPhoto4 animated:YES completion:NULL];
}

#pragma mark imagepicker delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    UIImage *image=[info objectForKey:UIImagePickerControllerEditedImage];
    
    if (picker == mPickerPhoto) {
        [self.mBtnPhoto setImage:image forState:UIControlStateNormal];
        mbPhotoChanged = YES;
    }
    if (picker == mPickerPhoto1) {
        [self.mBtnPhoto1 setImage:image forState:UIControlStateNormal];
        mbPhoto1 = YES;
        mbPhotoChanged1 = YES;
    }
    if (picker == mPickerPhoto2) {
        [self.mBtnPhoto2 setImage:image forState:UIControlStateNormal];
        mbPhoto2 = YES;
        mbPhotoChanged2 = YES;
    }
    if (picker == mPickerPhoto3) {
        [self.mBtnPhoto3 setImage:image forState:UIControlStateNormal];
        mbPhoto3 = YES;
        mbPhotoChanged3 = YES;
    }
    if (picker == mPickerPhoto4) {
        [self.mBtnPhoto4 setImage:image forState:UIControlStateNormal];
        mbPhoto4 = YES;
        mbPhotoChanged4 = YES;
    }
    
    [self showDeletePhotoButtons];
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark textfield delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    if (textField == self.mTxtNickname || textField == self.mTxtConfirmPassword)
    {
        [textField resignFirstResponder];
    }
    
    if (textField == self.mTxtPassword)
    {
        [self.mTxtConfirmPassword becomeFirstResponder];
    }
   
	return YES;
}


- (IBAction)onDistanceSlider:(id)sender
{
    NSString *strDistance = [NSString stringWithFormat:@"%dKM", (int)self.mSliderDistance.value];
    [self.mLblDistance setText:strDistance];
}

- (void)animationView:(CGFloat)yPos {
	if(yPos == self.view.frame.origin.y)
		return;
    //	self.view.userInteractionEnabled = NO;
	[UIView animateWithDuration:0.3
					 animations:^{
						 CGRect rt = self.view.frame;
						 rt.origin.y = yPos/* + 64*/;
						 self.view.frame = rt;
					 }completion:^(BOOL finished) {
                         //						 self.view.userInteractionEnabled = YES;
                     }];
}

#pragma mark - KeyBoard notifications
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if (textField == self.mTxtNickname)
    {
        mnHeightOffset = 30;
    }
    else
    {
        mnHeightOffset = -1;
    }
    
    return TRUE;
}

- (void)keyboardWillShow:(NSNotification*)notify {
    CGRect rtKeyBoard = [(NSValue*)[notify.userInfo valueForKey:@"UIKeyboardFrameEndUserInfoKey"] CGRectValue];
    
    if (mnHeightOffset > 0)
    {
        [self animationView:-mnHeightOffset];
    }
    else
    {
        [self animationView:-rtKeyBoard.size.height];
    }
}

- (void)keyboardWillHide:(NSNotification*)notify {
	[self animationView:0];
}

- (IBAction)onLogout:(id)sender
{
    [PFUser logOut];
    
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.delegate backToRootView];
}

- (IBAction)onDeleteAccount:(id)sender {
//    [self dismissViewControllerAnimated:YES completion:nil];
//    [self.delegate backToRootView];
}

- (void)enableDistanceView
{
    [self.mLblDistanceTitle setEnabled:self.mSwitchDistance.on];
    [self.mLblDistanceMin setEnabled:self.mSwitchDistance.on];
    [self.mLblDistanceMax setEnabled:self.mSwitchDistance.on];
    [self.mLblDistance setEnabled:self.mSwitchDistance.on];
    [self.mSliderDistance setEnabled:self.mSwitchDistance.on];
}

- (IBAction)onDistanceSwitch:(id)sender
{
    [self enableDistanceView];
}


@end
