//
//  RNKitSensor.m
//  RNKitSensor
//
//  Created by Snow on 2017/8/17.
//  Copyright © 2017年 SnowYang. All rights reserved.
//

#import "RNKitSensor.h"

#if __has_include(<React/RCTBridge.h>)
#import <React/RCTConvert.h>
#import <React/RCTLog.h>
#import <React/RCTUtils.h>
#import <React/RCTEventDispatcher.h>
#import <React/RCTRootView.h>
#else
#import "RCTConvert.h"
#import "RCTLog.h"
#import "RCTUtils.h"
#import "RCTEventDispatcher.h"
#import "RCTRootView.h"
#endif


#import "DataBaseHandle.h"
#import "DataBaseModel.h"
#import "Reachability.h"

#define kIOS9 ([[[UIDevice currentDevice] systemVersion] doubleValue] >= 9.0)


static dispatch_queue_t queue = nil;

@interface RNKitSensor ()
@property (nonatomic, strong) NSMutableArray *modelArray;
@end

@implementation RNKitSensor

RCT_EXPORT_MODULE();


RCT_EXPORT_METHOD(initializationDB())
{
    [self uploadWith:@"" requestUrl:@"" isInit:YES];
    RCTLogInfo(@"初始化");
}


RCT_EXPORT_METHOD(insertToDB:(NSString *)jsonBody requestUrl:(NSString *)requestUrl)
{
    RCTLogInfo(@"jsonBody:%@, requestUrl:%@", jsonBody,requestUrl);
    [self uploadWith:jsonBody requestUrl:requestUrl isInit:NO];
    
}



- (void)uploadWith:(NSString *)jsonBody requestUrl:(NSString *)requestUrl isInit:(BOOL)init {
    
    Reachability *reachAblilty = [Reachability reachabilityWithHostName:@"www.baidu.com"];
    NetworkStatus status = [reachAblilty currentReachabilityStatus];
    if (status == NotReachable){
        return;
    }

    self.modelArray = [NSMutableArray array];
    
    if (queue == nil) {
        queue = dispatch_queue_create("io.rnkit.sensor", DISPATCH_QUEUE_SERIAL);
    }
    dispatch_async(queue, ^{
        
        [[DataBaseHandle shareDataBase] openDB];

        if(init) {
            [[DataBaseHandle shareDataBase] deleteWithStatus:1];

        } else {
            NSDate *now = [NSDate date];
            DataBaseModel *model = [DataBaseModel new];
            model.jsonBody = [self isNullString:jsonBody] ? jsonBody : @"NO jsonBody";
            model.requestUrl = [self isNullString:requestUrl] ? requestUrl : @"NO requestUrl";
            model.timeStamp = (NSUInteger)(([now timeIntervalSince1970]) * 1000);
            model.times = 0;
            model.status = 0;
            [[DataBaseHandle shareDataBase] insertModel:model];
            //[[DataBaseHandle shareDataBase] deleteWithStatus:0];
        }
        
        for (DataBaseModel *model in [[DataBaseHandle shareDataBase] selectAll]) {
            @autoreleasepool {
                if (model.status == 0 || model.status == 2) {
                    /*
                     NSURL *url = [NSURL URLWithString:model.requestUrl];
                     NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
                     NSString *parmStr = [NSString stringWithFormat:@"jsonBody=%@&timeStamp=%lu",model.jsonBody,(unsigned long)model.timeStamp];
                     request.HTTPBody = [parmStr dataUsingEncoding:NSUTF8StringEncoding];
                     request.HTTPMethod = @"POST";
                     if (kIOS9) {
                     NSURLSession *session = [NSURLSession sharedSession];
                     NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                     if (error) {
                     
                     model.status = 2;
                     } else {
                     
                     model.status = 1;
                     }
                     }];
                     [task resume];
                     } else {
                     [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
                     if (connectionError) {
                     
                     model.status = 2;
                     } else {
                     
                     model.status = 1;
                     }
                     }];
                     model.times += 1;
                     }
                     */
                    model.times += 1;
                    if (model.mid % 2 == 0) {
                        model.status = 1;
                    }
                    
                    [self.modelArray addObject:model];
                }
            }
        }
        
        if (self.modelArray.count > 0) {
            [[DataBaseHandle shareDataBase] batchUpdeate:self.modelArray];
            
            [[DataBaseHandle shareDataBase] deleteWithStatus:1];
        }else {
            
            [[DataBaseHandle shareDataBase] resetId];
        }
        
        [[DataBaseHandle shareDataBase] closeDB];
        
    });
    
}

- (BOOL)isNullString:(id)value {
    NSString *str = [NSString stringWithFormat:@"%@",value];
    if (str == nil || [str isEqual:[NSNull null]] || [str isEqualToString:@""]) {
        return NO;
    }
    return YES;
}


@end
