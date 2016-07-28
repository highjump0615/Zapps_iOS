//
//  LoginViewController.m
//  Zapp
//
//  Created by highjump on 14-7-10.
//  Copyright (c) 2014年 Tian. All rights reserved.
//

#import "LoginViewController.h"
#import "MBProgressHUD.h"
#import "CommonUtils.h"

@interface LoginViewController ()

@property (weak, nonatomic) IBOutlet UITextField *mTxtUsername;
@property (weak, nonatomic) IBOutlet UITextField *mTxtPassword;
@property (weak, nonatomic) IBOutlet UIButton *mButFacebook;
@property (weak, nonatomic) IBOutlet UIButton *mButTwitter;

@end

@implementation LoginViewController

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
    self.mTxtPassword.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"PASSWORD" attributes:@{NSForegroundColorAttributeName: color}];
    
    PFUser *currentUser = [PFUser currentUser];
    if (currentUser) {
        CommonUtils* utils = [CommonUtils sharedObject];
        [utils gotoMain:self segue:@"Login2Home"];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.mTxtUsername setText:@""];
    [self.mTxtPassword setText:@""];
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

- (IBAction)onLogin:(id)sender
{
    // check if they are empty
    if(self.mTxtUsername.text.length == 0 || self.mTxtPassword.text.length == 0) {
		UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"Fill user name and password" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		return;
	}
    
    [PFUser logInWithUsernameInBackground:self.mTxtUsername.text password:self.mTxtPassword.text block:^(PFUser *user, NSError *error) {
        
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        
        if (user) {
            CommonUtils* utils = [CommonUtils sharedObject];
            [utils gotoMain:self segue:@"Login2Home"];
        } else {
            NSString *errorString = [error userInfo][@"error"];
            
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:errorString delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
    }];
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
}

- (IBAction)onButFacebook:(id)sender
{
    CommonUtils* utils = [CommonUtils sharedObject];
    [utils loginWithFacebook:self button:self.mButFacebook segue:@"Login2Home"];
}

- (IBAction)onButTwitter:(id)sender
{
    CommonUtils* utils = [CommonUtils sharedObject];
    [utils loginWithTwitter:self button:self.mButFacebook segue:@"Login2Home"];
}


#pragma mark - TextField delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if (textField == self.mTxtUsername)
    {
		[self.mTxtPassword becomeFirstResponder];
	}
    else if (textField == self.mTxtPassword)
    {
        [textField resignFirstResponder];
    }
    
	return YES;
}


@end
