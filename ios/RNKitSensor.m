//
//  RNKitSensor.m
//  RNKitSensor
//
//  Created by Snow on 2017/8/17.
//  Copyright © 2017年 SnowYang. All rights reserved.
//

#import "RNKitSensor.h"
#import <CommonCrypto/CommonDigest.h>

#if __has_include(<React/RCTBridge.h>)
#import <React/RCTConvert.h>
#import <React/RCTLog.h>
#else
#import "RCTConvert.h"
#import "RCTLog.h"
#endif


#import "DataBaseHandle.h"
#import "DataBaseModel.h"
#import "Reachability.h"

#define kIOS9 ([[[UIDevice currentDevice] systemVersion] doubleValue] >= 9.0)


static dispatch_queue_t queue = nil;

@interface RNKitSensor ()

@property (nonatomic, strong) NSMutableArray *modelArray;
@property (nonatomic, strong) NSMutableArray *jsonArray;
@property (nonatomic, assign) NSInteger maxVolume;//最大传送条数
@property (nonatomic, copy) NSString *appkey;
@property (nonatomic, assign) BOOL enterBackground;
@property (nonatomic, assign) NSInteger maxUploadNum;//有网情况下,上传失败,最多重复上传三次

@end

@implementation RNKitSensor

RCT_EXPORT_MODULE();


RCT_EXPORT_METHOD(initial:(NSString *)appkey maxVolume:(NSInteger)maxVolume)
{
    self.maxVolume = maxVolume;
    self.appkey = appkey;
    [self setupNotifications];
    RCTLogInfo(@"初始化");
}


RCT_EXPORT_METHOD(save:(NSString *)jsonBody requestUrl:(NSString *)requestUrl priorityLevel:(NSInteger)level)
{
    
    [[DataBaseHandle shareDataBase] openDB];
    
    NSDate *now = [NSDate date];
    DataBaseModel *model = [DataBaseModel new];
    model.jsonBody = [self isNullString:jsonBody] ? jsonBody : @"NO jsonBody";
    model.requestUrl = [self isNullString:requestUrl] ? requestUrl : @"NO requestUrl";
    model.priority = [self isNullString:@(level)] ? level : 20;
    model.timeStamp = (NSUInteger)(([now timeIntervalSince1970]) * 1000);
    model.times = 0;
    model.status = 0;
    [[DataBaseHandle shareDataBase] insertModel:model];
    
    [[DataBaseHandle shareDataBase] closeDB];
    
}


RCT_EXPORT_METHOD(check)
{
    [self upload];
    RCTLogInfo(@"启动线程");
    
}

- (void)upload {
    
    if (!(self.maxVolume && [self isNullString:self.appkey])) {
        NSLog(@"缺少上传最大量或者appkey值");
        return;
    }
    
    Reachability *reachAblilty = [Reachability reachabilityWithHostName:@"www.baidu.com"];
    NetworkStatus status = [reachAblilty currentReachabilityStatus];
    if (status == NotReachable){
        NSLog(@"无网络");
        return;
    }
    
    //    [[DataBaseHandle shareDataBase] openDB];
    //    [[DataBaseHandle shareDataBase] deleteWithStatus:1];
    
    if (queue == nil) {
        queue = dispatch_queue_create("io.rnkit.sensor", DISPATCH_QUEUE_SERIAL);
    }
    
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(queue, ^{
        while (true) {
            NSLog(@"循环了......");
            if (weakSelf.enterBackground) {
                NSLog(@"停止了.....");
                break;
            }
        }
        /*
         while (true) {
         
         if (weakSelf.enterBackground || weakSelf.maxUploadNum >= 3) {
         break;
         }
         
         
         if (((NSArray *)[[DataBaseHandle shareDataBase] selectWithLimit:weakSelf.maxVolume]).count > 0) {
         
         weakSelf.modelArray = [NSMutableArray array];
         weakSelf.jsonArray = [NSMutableArray array];
         
         for (DataBaseModel *model in [[DataBaseHandle shareDataBase] selectWithLimit:weakSelf.maxVolume]) {
         model.times += 1;
         [weakSelf.modelArray addObject:model];
         [weakSelf.jsonArray addObject:model.jsonBody];
         
         }
         
         [weakSelf request];
         
         } else {
         
         [[DataBaseHandle shareDataBase] resetId];
         
         [[DataBaseHandle shareDataBase] closeDB];
         
         break;
         }
         }
         */
    });

}


- (BOOL)isNullString:(id)value {
    NSString *str = [NSString stringWithFormat:@"%@",value];
    if (str == nil || [str isEqual:[NSNull null]] || [str isEqualToString:@""]) {
        return NO;
    }
    return YES;
}


- (NSString *)getMD5:(NSString *)string {
    
    const char *original_str = [string UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(original_str,(int)strlen(original_str), result);//调用md5
    NSMutableString *hash = [NSMutableString string];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++){
        [hash appendFormat:@"%02x", result[i]];
    }
    return hash;
}

- (void)request {
    
    NSDate *now = [NSDate date];
    NSUInteger timeStamp = (NSUInteger)(([now timeIntervalSince1970]) * 1000);
    
    NSMutableString *jsonStr = [NSMutableString string];
    for (NSString *jsonBody in self.jsonArray) {
        [jsonStr appendFormat:@"%@,",jsonBody];
    }
    jsonStr = ([jsonStr substringToIndex:jsonStr.length - 1]).mutableCopy;
    NSString *signatureString = [self getMD5:[NSString stringWithFormat:@"%@%@%lu",self.appkey,jsonStr,(unsigned long)timeStamp]];
    
    NSString *requestUrl = ((DataBaseModel *)self.modelArray[0]).requestUrl;
    NSURL *url = [NSURL URLWithString:requestUrl];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSString *parmStr = [NSString stringWithFormat:@"iscompress=false&signature=%@&timestamp=%lu",signatureString,(unsigned long)timeStamp];
    
    request.HTTPBody = [parmStr dataUsingEncoding:NSUTF8StringEncoding];
    request.HTTPMethod = @"POST";
    
    if (kIOS9) {
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            [self responseData:data error:error];
        }];
        [task resume];
    } else {
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
            [self responseData:data error:connectionError];
        }];
        
    }
    
    if (self.modelArray.count > 0) {
        [[DataBaseHandle shareDataBase] batchUpdeate:self.modelArray];
        [[DataBaseHandle shareDataBase] deleteWithStatus:1];
    }

}


- (void)responseData:(NSData *)data error:(NSError *)error {
    
    if (error) {
        [self changeStatus:2];
        self.maxUploadNum += 1;
    } else {
        
        NSDictionary *dict = [self toArrayOrNSDictionary:data];
        if (dict) {
            if ([dict[@"code"] intValue] == 1) {
                [self changeStatus:1];
                self.maxUploadNum = 0;
            } else {
                [self changeStatus:2];
                self.maxUploadNum += 1;
            }
        }else{
            [self changeStatus:2];
            self.maxUploadNum += 1;
        }
    }

}




- (void)changeStatus:(NSInteger)status {
    
    for (DataBaseModel *model in self.modelArray) {
        @autoreleasepool {
            model.status = status;
        }
    }
}



- (id)toArrayOrNSDictionary:(NSData *)jsonData{
    
    NSError *error = nil;
    
    id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&error];
    
    if (jsonObject != nil && error == nil) {
        
        return jsonObject;
        
    } else {
        
        return nil;
        
    }
    
}


- (void)setupNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
}


#pragma mark Background tasks

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    self.enterBackground = YES;
    NSLog(@"进入后台了");
}

- (void)applicationWillEnterForeground:(NSNotification *)notification
{
    self.enterBackground = NO;
    NSLog(@"前台最大量%ld",(long)self.maxVolume);
    [self upload];
  
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
