//
//  ShareView.m
//  Zapp
//
//  Created by highjump on 14-7-29.
//  Copyright (c) 2014年 Tian. All rights reserved.
//

#import "ShareView.h"
#import "CommonUtils.h"
#import <MessageUI/MFMailComposeViewController.h>

#import "MBProgressHUD.h"
#import <Twitter/Twitter.h>


@interface ShareView ()
{
    ZappData *mZapp;
    CommentData *mComment;
}

@end


@implementation ShareView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)showShadow
{
    // shadow on share panel
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:self.bounds];
    self.layer.masksToBounds = NO;
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOffset = CGSizeMake(0.0f, -3.0f);
    self.layer.shadowOpacity = 0.3f;
    self.layer.shadowPath = shadowPath.CGPath;
}

- (void)setZappData:(id)data
{
    mZapp = nil;
    mComment = nil;
    
    if ([data isKindOfClass:[ZappData class]])
    {
        mZapp = (ZappData *)data;
    }
    else if ([data isKindOfClass:[CommentData class]])
    {
        mComment = (CommentData *)data;
    }
}

- (IBAction)onCopy:(id)sender
{
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    
    if (mZapp)
    {
        pasteboard.string = mZapp.zappFile.url;
    }
    else if (mComment)
    {
        pasteboard.string = mComment.voiceFile.url;
    }
    
    [self onCancel:nil];
}

- (IBAction)onEmail:(id)sender
{
    MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
    UIViewController *viewController = (UIViewController *)self.delegate;
    controller.mailComposeDelegate = viewController;
    
    [controller setSubject:@"Zapps Share"];
    
    //    NSArray *toRecipients = [NSArray arrayWithObjects:@"fisrtMail@example.com", @"secondMail@example.com", nil];
    //    [controller setToRecipients:toRecipients];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:viewController.view animated:YES];
    [hud setLabelText:@"Processing Audio Data..."];

    if (mZapp)
    {
        [controller addAttachmentData:[mZapp.zappFile getData] mimeType:@"audio/mpeg" fileName:@"zapp.mp3"];
        [controller setMessageBody:mZapp.strDescription isHTML:NO];
    }
    else if (mComment)
    {
        [controller addAttachmentData:[mComment.voiceFile getData] mimeType:@"audio/mpeg" fileName:@"zapp.mp3"];
        [controller setMessageBody:mComment.strContent isHTML:NO];
    }
    
    [MBProgressHUD hideHUDForView:viewController.view animated:YES];
    
    if (controller)
    {
        [viewController.navigationController presentViewController:controller animated: YES completion:^{
        }];
    }
    
    [self onCancel:nil];
}

- (IBAction)onFacebook:(id)sender
{
    UIViewController *viewController = (UIViewController *)self.delegate;
    CommonUtils *utils = [CommonUtils sharedObject];
    
    if (mZapp)
    {
        [utils shareToFacebook:viewController text:mZapp.strDescription url:mZapp.zappFile.url];
    }
    else if (mComment)
    {
        [utils shareToFacebook:viewController text:mComment.strContent url:mComment.voiceFile.url];
    }
    
    [self onCancel:nil];
}

- (IBAction)onTwitter:(id)sender
{
    UIViewController *viewController = (UIViewController *)self.delegate;
    CommonUtils *utils = [CommonUtils sharedObject];

    if (mZapp)
    {
        [utils shareToTwitter:viewController text:mZapp.strDescription url:mZapp.zappFile.url];
    }
    else if (mComment)
    {
        [utils shareToTwitter:viewController text:mComment.strContent url:mComment.voiceFile.url];
    }
    
    [self onCancel:nil];
}

- (IBAction)onCancel:(id)sender
{
    [self.delegate hideShareView];
}


@end
