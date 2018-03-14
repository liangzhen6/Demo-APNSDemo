//
//  NotificationService.m
//  NotificationServer
//
//  Created by shenzhenshihua on 2017/3/17.
//  Copyright © 2017年 shenzhenshihua. All rights reserved.
//

#import "NotificationService.h"
#import <AVFoundation/AVFoundation.h>
@interface NotificationService ()

@property (nonatomic, strong) void (^contentHandler)(UNNotificationContent *contentToDeliver);
@property (nonatomic, strong) UNMutableNotificationContent *bestAttemptContent;

@end

@implementation NotificationService

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler {
    self.contentHandler = contentHandler;
    self.bestAttemptContent = [request.content mutableCopy];
    
/*
 UNNotificationActionOptionAuthenticationRequired  执行前需要解锁确认
 UNNotificationActionOptionDestructive  显示高亮（红色）
 UNNotificationActionOptionForeground  将会引起程序启动到前台
 
 */
    
#warning 这里是添加一些事件的，比如点击进入查看详情，快捷回复等
    NSMutableArray *actionMutableArr = [[NSMutableArray alloc] initWithCapacity:1];
    UNNotificationAction * actionA  =[UNNotificationAction actionWithIdentifier:@"ActionA" title:@"不感兴趣" options:UNNotificationActionOptionAuthenticationRequired];
    
    UNNotificationAction * actionB = [UNNotificationAction actionWithIdentifier:@"ActionB" title:@"不感兴趣" options:UNNotificationActionOptionDestructive];
    
    UNNotificationAction * actionC = [UNNotificationAction actionWithIdentifier:@"ActionC" title:@"进去瞅瞅" options:UNNotificationActionOptionForeground];
    UNTextInputNotificationAction * actionD = [UNTextInputNotificationAction actionWithIdentifier:@"ActionD" title:@"作出评论" options:UNNotificationActionOptionDestructive textInputButtonTitle:@"send" textInputPlaceholder:@"say some thing"];
    
    [actionMutableArr addObjectsFromArray:@[actionA,actionB,actionC,actionD]];
    
    if (actionMutableArr.count) {
        UNNotificationCategory * notficationCategory = [UNNotificationCategory categoryWithIdentifier:@"categoryNoOperationAction" actions:actionMutableArr intentIdentifiers:@[@"ActionA",@"ActionB",@"ActionC",@"ActionD"] options:UNNotificationCategoryOptionCustomDismissAction];
        
        [[UNUserNotificationCenter currentNotificationCenter] setNotificationCategories:[NSSet setWithObject:notficationCategory]];
        
    }
    
    
    //推送字段
    /*
    //视频

     {
     "aps":{
     "alert":{
     "title":"Realtime Custom Push Notifications",
     "subtitle":"Now with iOS 10 support!",
     "body":"Add multimedia content to your notifications"
     },
     "sound":"default",
     "badge": 1,
     "mutable-content": 1,
     "category": "realtime",
     },
     "media":{"type":"video","url":"http://olxnvuztq.bkt.clouddn.com/WeChatSight1.mp4"}
     }
     
     在推送视频的时候可能会因为视频比较大，消息送来有些慢，因为需要先下载多媒体文件；
     
     //图片
     
     {
     "aps":{
     "alert":{
     "title":"Realtime Custom Push Notifications",
     "subtitle":"Now with iOS 10 support!",
     "body":"Add multimedia content to your notifications"
     },
     "sound":"default",
     "badge": 1,
     "mutable-content": 1,
     "category": "realtime",
     },
     "media":{"type":"image","url":"https://www.fotor.com/images2/features/photo_effects/e_bw.jpg"}
     }
    
     对应的url“”前千万不要有空格
     
     "mutable-content": 1,代表自定义了推送 例如图片、视频、声音等
     "content-available":1, 静默推送
     
     */
#warning  这里需要注意当推送带有图片、视频、声音时，必须要在"aps"这个字典下增加     "mutable-content": 1,这个字段，否则不会显示图片、声音、视频；至于多媒体的字段你也可以与后台商量一下如何制定；
    
#pragma mark====================添加=categoryIdentifier============
    self.bestAttemptContent.categoryIdentifier = @"categoryNoOperationAction";//myNotificationCategory categoryNoOperationAction
    // Modify the notification content here...
    //    self.bestAttemptContent.title = [NSString stringWithFormat:@"点击查看更多内容"];
//    self.bestAttemptContent.sound = nil;//禁止播放声音
    
    NSDictionary *dict =  self.bestAttemptContent.userInfo;
    //    NSDictionary *notiDict = dict[@"aps"];
    NSString *mediaUrl = [NSString stringWithFormat:@"%@",dict[@"media"][@"url"]];
    NSLog(@"%@",mediaUrl);
    if (!mediaUrl.length) {
        self.contentHandler(self.bestAttemptContent);
    }
    [self loadAttachmentForUrlString:mediaUrl withType:dict[@"media"][@"type"] completionHandle:^(UNNotificationAttachment *attach) {
        
        if (attach) {
            self.bestAttemptContent.attachments = [NSArray arrayWithObject:attach];
        }
        self.contentHandler(self.bestAttemptContent);
    }];

    

}

//处理视频，图片的等多媒体
- (void)loadAttachmentForUrlString:(NSString *)urlStr
                          withType:(NSString *)type
                  completionHandle:(void(^)(UNNotificationAttachment *attach))completionHandler{
    __block UNNotificationAttachment *attachment = nil;
    NSURL *attachmentURL = [NSURL URLWithString:urlStr];
    NSString *fileExt = [self fileExtensionForMediaType:type];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    [[session downloadTaskWithURL:attachmentURL
                completionHandler:^(NSURL *temporaryFileLocation, NSURLResponse *response, NSError *error) {
                    if (error != nil) {
                        NSLog(@"%@", error.localizedDescription);
                    } else {
                        
                        NSFileManager *fileManager = [NSFileManager defaultManager];
                        NSURL *localURL = [NSURL fileURLWithPath:[temporaryFileLocation.path stringByAppendingString:fileExt]];
                        [fileManager moveItemAtURL:temporaryFileLocation toURL:localURL error:&error];
#pragma mark  自定义推送UI需要=========开始=========
                        
                       NSMutableDictionary * dict = [self.bestAttemptContent.userInfo mutableCopy];
                        [dict setObject:[NSData dataWithContentsOfURL:localURL] forKey:@"image"];
                        self.bestAttemptContent.userInfo = dict;
 #pragma mark  自定义推送UI需要========结束=========
                        NSError *attachmentError = nil;
                        
                        attachment = [UNNotificationAttachment attachmentWithIdentifier:@"" URL:localURL options:nil error:&attachmentError];
                        
                        if (attachmentError) {
                            NSLog(@"%@", attachmentError.localizedDescription);
                        }
                    }
                    completionHandler(attachment);
                }] resume];
    
}

- (NSString *)fileExtensionForMediaType:(NSString *)type {
    NSString *ext = type;
    if ([type isEqualToString:@"image"]) {
        ext = @"jpg";
    }
    if ([type isEqualToString:@"video"]) {
        ext = @"mp4";
    }
    if ([type isEqualToString:@"audio"]) {
        ext = @"mp3";
    }
    return [@"." stringByAppendingString:ext];
}
//合成收款语音播报  例如 收款到账  外卖订单处理等
- (void)syntheticVoice:(NSString *)string {
    // 语音合成
    AVSpeechSynthesizer * synthesizer = [[AVSpeechSynthesizer alloc] init];
    AVSpeechUtterance *speechUtterance = [AVSpeechUtterance speechUtteranceWithString:string];
    //设置语言类别（不能被识别，返回值为nil）
    speechUtterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"zh-CN"];//汉语
    //设置语速快慢
    speechUtterance.rate = 0.55;
    //语音合成器会生成音频
    [synthesizer speakUtterance:speechUtterance];
}


- (void)serviceExtensionTimeWillExpire {
    // Called just before the extension will be terminated by the system.
    // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
    self.contentHandler(self.bestAttemptContent);
}

@end
