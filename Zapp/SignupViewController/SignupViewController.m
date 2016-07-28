//
//  SignupViewController.m
//  Zapp
//
//  Created by highjump on 14-7-10.
//  Copyright (c) 2014年 Tian. All rights reserved.
//

#import "SignupViewController.h"
#import "MBProgressHUD.h"
#import "CommonUtils.h"

@interface SignupViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>
{
    UIImage *mImgPhoto;
}

@property (weak, nonatomic) IBOutlet UITextField *mTxtUsername;
@property (weak, nonatomic) IBOutlet UITextField *mTxtEmail;
@property (weak, nonatomic) IBOutlet UITextField *mTxtPassword;
@property (weak, nonatomic) IBOutlet UITextField *mTxtRPassword;

@property (weak, nonatomic) IBOutlet UIButton *mButPhoto;
@property (weak, nonatomic) IBOutlet UIButton *mButFacebook;

@end

@implementation SignupViewController

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
    
    UIColor *color = [UIColor whiteColor];
    self.mTxtUsername.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"USERNAME" attributes:@{NSForegroundColorAttributeName: color}];
    self.mTxtEmail.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"EMAIL ADDRESS" attributes:@{NSForegroundColorAttributeName: color}];
    self.mTxtPassword.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"PASSWORD" attributes:@{NSForegroundColorAttributeName: color}];
    self.mTxtRPassword.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"REPEAT PASSWORD" attributes:@{NSForegroundColorAttributeName: color}];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
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

-(void)dismissKeyboard {
    [self.view endEditing:YES];
}

- (IBAction)onButPhoto:(id)sender
{
    UIImagePickerController *pickerPhoto = [[UIImagePickerController alloc] init];
    pickerPhoto.delegate = self;
    pickerPhoto.allowsEditing = YES;
    pickerPhoto.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
	
    [self presentViewController:pickerPhoto animated:YES completion:NULL];
}

- (IBAction)onBack:(id)sender {
    [[self navigationController] popViewControllerAnimated:YES];
}

- (IBAction)onSignup:(id)sender {
    // check if they are empty
    if (self.mTxtUsername.text.length == 0 || self.mTxtEmail.text.length == 0) {
		UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"Fill user name and email address" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		return;
	}
    
    if (self.mTxtPassword.text.length == 0)
    {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"Input your password" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		return;
    }
    
    if (![self.mTxtPassword.text isEqualToString:self.mTxtRPassword.text])
    {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"Password does not match" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		return;
    }
    
    // Start request
    PFUser *user = [PFUser user];
    
    // init user
    user.username = self.mTxtUsername.text;
    user.password = self.mTxtPassword.text;
    user.email = self.mTxtEmail.text;
    user[@"distanceFilter"] = [NSNumber numberWithBool:NO];
    user[@"distance"] = [NSNumber numberWithInteger:50];
    
    if (mImgPhoto)
    {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        // saving photo image
        UIImage* convertImage = [CommonUtils imageWithImage:mImgPhoto scaledToSize:CGSizeMake(290, 290)];
        
        NSData *imageData = UIImageJPEGRepresentation(convertImage, 10);
        
        PFFile *imageFile = [PFFile fileWithName:@"photo.jpg" data:imageData];
        
        // Save PFFile
        [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
        {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            if (!error)
            {
                // Create a PFObject around a PFFile and associate it with the current user
                user[@"photo"] = imageFile;
                [self saveUserInfo:user];
            }
            else{
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:[error userInfo][@"error"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
            }
        }];
        
        // photo thumb
        UIImage *imagePhotoThumb = [CommonUtils imageWithImage:mImgPhoto scaledToSize:CGSizeMake(80, 80)];
        NSData *dataPhotoThumb = UIImageJPEGRepresentation(imagePhotoThumb, 10);
        PFFile *imageFileThumb = [PFFile fileWithName:@"photoThumb.jpg" data:dataPhotoThumb];
        [imageFileThumb saveInBackground];
        user[@"photothumb"] = imageFileThumb;
    }
    else
    {
        [self saveUserInfo:user];
    }
}

- (void)saveUserInfo:(PFUser *)user
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];

    [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        
        if (!error) {
            CommonUtils* utils = [CommonUtils sharedObject];
            [utils gotoMain:self segue:@"Signup2Home"];
        } else {
            NSString *errorString = [error userInfo][@"error"];
            
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:errorString delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
    }];
}

- (IBAction)onFacebook:(id)sender
{
    CommonUtils* utils = [CommonUtils sharedObject];
    [utils loginWithFacebook:self button:self.mButFacebook segue:@"Signup2Home"];
}

- (IBAction)onTwitter:(id)sender
{
    CommonUtils* utils = [CommonUtils sharedObject];
    [utils loginWithTwitter:self button:self.mButFacebook segue:@"Signup2Home"];
}


#pragma mark - TextField delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if (textField == self.mTxtUsername)
    {
		[self.mTxtEmail becomeFirstResponder];
	}
    else if (textField == self.mTxtEmail)
    {
        [self.mTxtPassword becomeFirstResponder];
    }
    else if (textField == self.mTxtPassword)
    {
        [self.mTxtRPassword becomeFirstResponder];
    }
    else
    {
        [textField resignFirstResponder];
    }
    
	return YES;
}

#pragma mark - UIImagePickerController delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    mImgPhoto = [info objectForKey:UIImagePickerControllerEditedImage];
    
    [self.mButPhoto setImage:mImgPhoto forState:UIControlStateNormal];
        
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
