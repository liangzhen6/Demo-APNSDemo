//
//  NotificationViewController.m
//  NotificationViewController
//
//  Created by shenzhenshihua on 2017/3/17.
//  Copyright © 2017年 shenzhenshihua. All rights reserved.
//

#import "NotificationViewController.h"
#import <UserNotifications/UserNotifications.h>
#import <UserNotificationsUI/UserNotificationsUI.h>

@interface NotificationViewController () <UNNotificationContentExtension>

@property IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UIImageView *myImageView;

@end

@implementation NotificationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.myImageView.layer.masksToBounds = YES;
    // Do any required interface initialization here.
}

- (void)didReceiveNotification:(UNNotification *)notification {
    NSDictionary * userInfo = notification.request.content.userInfo;
    NSLog(@"%@",userInfo);
    NSData * data = [userInfo objectForKey:@"image"];
    self.myImageView.image = [UIImage imageWithData:data];
    self.label.text = notification.request.content.body;
}

@end
