//
//  CircleProgressView.m
//  Zapp
//
//  Created by highjump on 14-7-14.
//  Copyright (c) 2014年 Tian. All rights reserved.
//

#import "CircleProgressView.h"

@implementation CircleProgressView

#define DEGREES_TO_RADIANS(degrees)((M_PI * degrees)/180)

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    float fRadius = 132.0f;
    float fInteralRadius = 129.0f;
    
    //General circle info
    CGPoint center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
    float strokeWidth = fRadius - fInteralRadius;
    float radius = fInteralRadius + strokeWidth / 2;
    
    //Active circle
    float startAngle = 152;
    
    float tempDegrees = self.mfPercentageCompleted * 236 / 100.f + startAngle;
    int nDegrees = (int)tempDegrees % 360;
    
    UIBezierPath *circle2 = [UIBezierPath bezierPathWithArcCenter:center
                                                           radius:radius
                                                       startAngle:DEGREES_TO_RADIANS(startAngle)
                                                         endAngle:DEGREES_TO_RADIANS(nDegrees)
                                                        clockwise:YES];
    [[UIColor colorWithRed:149/255.0 green:134/255.0 blue:164/255.0 alpha:1] setStroke];
    circle2.lineWidth = strokeWidth;
    [circle2 stroke];
}


@end
