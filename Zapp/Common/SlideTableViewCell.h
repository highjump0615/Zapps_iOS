//
//  SlideTableViewCell.h
//  Zapp
//
//  Created by highjump on 14-7-12.
//  Copyright (c) 2014年 Tian. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SlideTableViewCell : UITableViewCell <UIGestureRecognizerDelegate>
{
    UISwipeGestureRecognizer * _leftGestureRecognizer;
    UISwipeGestureRecognizer * _rightGestureRecognizer;
}

@property (weak, nonatomic) IBOutlet UIView *mViewContent;
@property (assign) int mnMode;

@property (weak, nonatomic) IBOutlet UIButton *mButShare;
@property (weak, nonatomic) IBOutlet UIButton *mButReport;
@property (weak, nonatomic) IBOutlet UIButton *mButDelete;

-(void) swipeMenu;


@end
