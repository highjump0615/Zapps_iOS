//
//  SlideTableViewCell.m
//  Zapp
//
//  Created by highjump on 14-7-12.
//  Copyright (c) 2014年 Tian. All rights reserved.
//

#import "SlideTableViewCell.h"

@implementation SlideTableViewCell

const static CGFloat sfShareReportWidth = 145.f;
const static CGFloat sfDeleteWidth = 200.f;


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void) swipeMenu
{
    _leftGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swiped:)];
    _leftGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    _leftGestureRecognizer.delegate = self;
    [self addGestureRecognizer:_leftGestureRecognizer];
    
    _rightGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swiped:)];
    _rightGestureRecognizer.delegate = self;
    _rightGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    [self addGestureRecognizer:_rightGestureRecognizer];
    
    // close the swipe menu
    self.mViewContent.frame = CGRectMake(0, self.mViewContent.frame.origin.y, self.mViewContent.frame.size.width, self.mViewContent.frame.size.height);
}

- (void)swiped:(UISwipeGestureRecognizer *)gestureRecognizer
{
    CGFloat cellXOffset;
    
    if (gestureRecognizer == _leftGestureRecognizer)
    {
        if (self.mnMode == 0)   // home
        {
            cellXOffset = -sfShareReportWidth;
        }
        else    // profile
        {
            cellXOffset = -sfDeleteWidth;
        }
    }
    else if (gestureRecognizer == _leftGestureRecognizer)
    {
        cellXOffset = 0;
    }
    
    [UIView animateWithDuration:0.2f animations:^{
        self.mViewContent.frame = CGRectMake(cellXOffset, self.mViewContent.frame.origin.y, self.mViewContent.frame.size.width, self.mViewContent.frame.size.height);
    }];
    
}


@end
