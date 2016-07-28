//
//  CommonUtils.h
//  Zapp
//
//  Created by highjump on 14-7-11.
//  Copyright (c) 2014年 Tian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#define TEXT_FACTOR 120

@interface CommentData : NSObject

@property (strong) NSString *strId;
@property (strong) NSString *strUsername;
@property (strong) NSString *strContent;
@property (nonatomic) int type;
@property (strong) NSDate *date;
@property (strong) PFUser *user;
@property (strong) PFObject *object;
@property (strong) PFFile *voiceFile;

- (CommentData *)initWithData:(PFObject *)commentObject;

@end


@interface NotificationData : NSObject

@property (strong) PFUser *user;
@property (strong) NSString *strUsername;
@property (nonatomic) int notificationType;
@property (strong) PFObject *zapp;
@property (strong) NSString *strAudioFile;
@property (nonatomic) int type;
@property (strong) NSDate *date;
@property (strong) PFObject *object;

- (NotificationData *)initWithData:(PFObject *)notificationObject;

@end



@interface ZappData : NSObject

@property (strong) NSString *strId;
@property (strong) NSString *strUsername;
@property (assign) int type;
@property (strong) NSString *strDescription;
@property (strong) PFFile *zappFile;
@property (strong) NSDate *date;
@property (strong) PFUser *user;

@property (strong) PFObject *object;

@property (nonatomic) int bLiked; // 1: like, 0: unliked, -1: not determinded
@property (nonatomic) int nLikeCount;
@property (nonatomic) int nCommentCount;
@property (nonatomic) int nPlayCount;

- (ZappData *)initWithZapp:(PFObject *)zappObject;
- (void)fillData:(PFObject *)zappObject;

@end


@interface CommonUtils : NSObject

@property (nonatomic, strong) CLLocation *mCurrentLocation;
@property (nonatomic, strong) AVAudioPlayer *mCurrentPlayer;
@property (nonatomic, strong) NSMutableArray *mZappList;

@property (strong) NSString *strNotifyType;
@property (strong) PFObject *notifyZappObj;

@property (assign) BOOL mbNeedRefresh;


+ (id)sharedObject;

+ (NSString *)getUsernameToShow:(PFUser *)user;
+ (NSString *)getTimeString:(NSDate *)date;
+ (int)getHeight:(NSString *)text fontsize:(int)nFontSize width:(int)nWidth height:(int)nHeight;

- (void)reportEmail:(UIViewController *)viewController;
- (void)gotoMain:(UIViewController *)displayView segue:(NSString *)segueString;
- (void)loginWithFacebook:(UIViewController *)viewController button:(UIButton *)button segue:(NSString *)segueString;
- (void)loginWithTwitter:(UIViewController *)viewController button:(UIButton *)button segue:(NSString *)segueString;
- (BOOL)convertToMp3:(NSURL *)source destination:(NSURL *)destination;

- (void)stopCurrentPlaying;

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;
+ (UIImage *)imageWithImage: (UIImage*) sourceImage scaledToHeight: (float) i_height width:(float)i_width;

- (void)shareToFacebook:(UIViewController *)viewController text:(NSString *)strContent url:(NSString *)strUrl;
- (void)shareToTwitter:(UIViewController *)viewController text:(NSString *)strContent url:(NSString *)strUrl;

@end


