//
//  AppDelegate.m
//  Zapp
//
//  Created by highjump on 14-7-5.
//  Copyright (c) 2014年 Tian. All rights reserved.
//

#import "AppDelegate.h"
#import "CommonUtils.h"
#import <FacebookSDK/FacebookSDK.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    [Parse setApplicationId:@"iWHFfoAM40p5dxk6H10QleBuyUcnRzn1YzVBBQCS"
                  clientKey:@"BHafxghjlo6MdCfFsF6fNw14Md4Gn5ieQPf0r4zB"];
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    
    // Facebook
    [PFFacebookUtils initializeFacebook];
    
    // Twitter
    [PFTwitterUtils initializeWithConsumerKey:@"3KEaBWSnU7YrCxsAsr3oDY10i"
                               consumerSecret:@"DU4zpZ7M4YWZr1BBdj38aRqQ0WTxg8ho4NyHNjGo5rfDLT9fG1"];
    
    // Register for push notifications
    [application registerForRemoteNotificationTypes: UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound];
    
    //
    // getting notification
    //
    // Extract the notification data
    NSDictionary *notificationPayload = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
    
    CommonUtils *utils = [CommonUtils sharedObject];
    utils.strNotifyType = [notificationPayload objectForKey:@"notifyType"];
    NSString *strNotifyZappId = [notificationPayload objectForKey:@"notifyZapp"];
    utils.notifyZappObj = [PFObject objectWithoutDataWithClassName:@"Zapps" objectId:strNotifyZappId];
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [FBAppCall handleDidBecomeActiveWithSession:[PFFacebookUtils session]];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    return [FBAppCall handleOpenURL:url
                  sourceApplication:sourceApplication
                        withSession:[PFFacebookUtils session]];
}

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken
{
    // Store the deviceToken in the current installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:newDeviceToken];
    [currentInstallation saveInBackground];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [PFPush handlePush:userInfo];
    
    if ( application.applicationState == UIApplicationStateActive ) {
        // app was already in the foreground
        PFInstallation *currentInstallation = [PFInstallation currentInstallation];
        if (currentInstallation.badge > 0) {
            currentInstallation.badge = 0;
            [currentInstallation saveEventually];
            
            [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
        }
    }
    else {
        // app was just brought from background to foreground
        CommonUtils *utils = [CommonUtils sharedObject];
        utils.strNotifyType = [userInfo objectForKey:@"notifyType"];
        NSString *strNotifyZappId = [userInfo objectForKey:@"notifyZapp"];
        utils.notifyZappObj = [PFObject objectWithoutDataWithClassName:@"Zapps" objectId:strNotifyZappId];
    }
}


@end
