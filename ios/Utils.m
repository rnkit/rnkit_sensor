//
//  Utils.m
//  RNKitSensor
//
//  Created by Snow on 2017/8/25.
//  Copyright © 2017年 SnowYang. All rights reserved.
//

#import "Utils.h"
#import <CommonCrypto/CommonDigest.h>
#import <AdSupport/AdSupport.h>
#import "DataBaseHandle.h"
#import "DataBaseModel.h"
#import "Reachability.h"
#import "LFCGzipUtillity.h"

#define kIOS9 ([[[UIDevice currentDevice] systemVersion] doubleValue] >= 9.0)

static dispatch_queue_t queue = nil;

static dispatch_semaphore_t semaphore = nil;

static NSInteger maxVolumeNum = 0;

static NSString *appkeyStr;

static NSInteger repeatCount = 3;

static NSString *logEvent = @"evnt_ckapp_log_collect";

@interface Utils ()<NSURLSessionDelegate>

@property (nonatomic, strong) NSMutableArray *modelArray;
@property (nonatomic, assign) BOOL enterBackground;

@end

@implementation Utils


- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupNotifications];
    }
    return self;
}



- (void)initial:(NSString *)appkey maxVolume:(NSInteger)maxVolume repeatTimes:(NSInteger)repeatTimes {
    maxVolumeNum = maxVolume;
    appkeyStr = appkey;
    repeatCount = repeatTimes;
}



- (void)insertToDB:(NSString *)jsonBody requestUrl:(NSString *)requestUrl priorityLevel:(NSInteger)level {
    
    NSDate *now = [NSDate date];
    DataBaseModel *model = [DataBaseModel new];
    model.jsonBody = [self isNullString:jsonBody] ? jsonBody : @"NO jsonBody";
    model.requestUrl = [self isNullString:requestUrl] ? requestUrl : @"NO requestUrl";
    model.priority = [self isNullString:@(level)] ? level : 20;
    model.timeStamp = (NSUInteger)(([now timeIntervalSince1970]) * 1000);
    model.times = 0;
    model.status = 0;
    [[DataBaseHandle shareDataBase] insertModel:model];
   
}


- (void)upload {
    
    
    if (!([self isNullString:appkeyStr])) {
        NSLog(@"缺少appkey值");
        return;
    }
    
    Reachability *reachAblilty = [Reachability reachabilityWithHostName:@"www.baidu.com"];
    NetworkStatus status = [reachAblilty currentReachabilityStatus];
    if (status == NotReachable){
        NSLog(@"无网络");
        return;
    }
    
    //一次最多循环5次
    __block int loopTimes = 0;
    
    if (queue == nil) {
        queue = dispatch_queue_create("io.rnkit.sensor", DISPATCH_QUEUE_SERIAL);
    }
    
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(queue, ^{
        __strong typeof(self) strongSelf = weakSelf;
        @try {
            while (true) {
                
                NSArray *failArr = [[DataBaseHandle shareDataBase] selectWithRepeatCount:repeatCount];
                int failCount = (int)failArr.count;
                
                if (failCount > 0) {
                    
                    for (DataBaseModel *model in failArr) {
                        [strongSelf addLog:model.jsonBody reason:@"事件因为失败次数过多而删除" requestUrl:model.requestUrl];
                    }
                    
                    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                    int preCount = [[defaults objectForKey:@"fail_repeatCount"] intValue];
                    int nowCount = preCount + failCount;
                    [defaults setObject:@(nowCount) forKey:@"fail_repeatCount"];
                    [defaults synchronize];
                    [[DataBaseHandle shareDataBase] deleteWithStatus:1 repeatCount:repeatCount];
                }
                
                if (strongSelf.enterBackground || loopTimes > 4) {
                    break;
                }
                
                loopTimes++;
                
                NSArray *dbArray = [[DataBaseHandle shareDataBase] selectWithLimit:maxVolumeNum];
                
                if (dbArray.count > 0) {
                    strongSelf.modelArray = [NSMutableArray array];
                    @try {
                        for (DataBaseModel *model in dbArray) {
                            
                            model.times += 1;
                            [strongSelf.modelArray addObject:model];
                            
                            NSDate *now = [NSDate date];
                            NSUInteger timeStamp = (NSUInteger)(([now timeIntervalSince1970]) * 1000);
                            NSDictionary *event = [strongSelf toArrayOrNSDictionaryFromData:[model.jsonBody dataUsingEncoding:NSUTF8StringEncoding]];
                            
                            NSDictionary *dict = @{@"timestamp":[NSString stringWithFormat:@"%lu",(unsigned long)timeStamp],
                                                   @"distinct_id":[self idfa],
                                                   @"bizType":@"B005",
                                                   @"events":@[event]
                                                   };
                            
                            [strongSelf requestWithJsonBody:[strongSelf toJsonStringFromParam:dict] model:model];
                        }
                        
                        [[DataBaseHandle shareDataBase] batchUpdeate:self.modelArray];
                        [[DataBaseHandle shareDataBase] deleteWithStatus:1];
                        
                        
                    } @catch (NSException *exception) {
                        NSLog(@"错误===%@",exception.description);
                    } @finally {
                        NSLog(@"finally");
                    }
                    
                } else {
                    break;
                }
            }
        } @catch (NSException *exception) {
            NSLog(@"错误===%@",exception.description);
        } @finally {
            NSLog(@"finally");
        }
        
    });
    
    
    
}


- (void)requestWithJsonBody:(NSString *)jsonBody model:(DataBaseModel *)model{
    
    @try {
        NSDate *now = [NSDate date];
        NSUInteger timeStamp = (NSUInteger)(([now timeIntervalSince1970]) * 1000);
        
        NSString *signatureString = [[self getMD5:[NSString stringWithFormat:@"%@%@%lu",jsonBody,appkeyStr,(unsigned long)timeStamp]] lowercaseString];
        
        NSURL *url = [NSURL URLWithString:model.requestUrl];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        request.HTTPMethod = @"POST";
        request.timeoutInterval = 10.0;
        
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:@"true" forHTTPHeaderField:@"iscompress"];
        [request setValue:signatureString forHTTPHeaderField:@"content-md5"];
        [request setValue:[NSString stringWithFormat:@"%lu",(unsigned long)timeStamp] forHTTPHeaderField:@"content-timestamp"];
        
        request.HTTPBody = [[LFCGzipUtillity gzipData:[jsonBody dataUsingEncoding:NSUTF8StringEncoding]] base64EncodedDataWithOptions:0];
        
        if (semaphore == nil) {
            semaphore = dispatch_semaphore_create(0);
        }
        
        if (kIOS9) {
            
            NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
            NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
            
            NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                
                [self responseData:data error:error withModel:model];
                
                dispatch_semaphore_signal(semaphore);
            }];
            [task resume];
            dispatch_semaphore_wait(semaphore,DISPATCH_TIME_FOREVER);
        } else {
            NSError *error = nil;
            NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&error];
            [self responseData:data error:error withModel:model];
            
        }
        
    } @catch (NSException *exception) {
        NSLog(@"错误===%@",exception.description);
    } @finally {
        NSLog(@"finally");
    }
    
    
}


- (NSString *)idfa
{
    if ([[ASIdentifierManager sharedManager] isAdvertisingTrackingEnabled]) {
        return [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    } else {
        return [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    }
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


- (void)changeWithID:(NSInteger)mid withStatus:(NSInteger)status {
    for (DataBaseModel *model in self.modelArray) {
        @autoreleasepool {
            if (model.mid == mid) {
                model.status = status;
            }
        }
    }
}



- (void)responseData:(NSData *)data error:(NSError *)error withModel:(DataBaseModel *)model{
    
    if (error) {
        [self changeWithID:model.mid withStatus:2];
        
    } else {
        
        NSDictionary *dict = [self toArrayOrNSDictionaryFromData:data];
        NSLog(@"返回字典是:====%@",dict);
        NSLog(@"返回信息是:====%@",dict[@"msg"]);
        if (dict) {
            if ([self isNullString:dict[@"flag"]] && [@"S" isEqualToString:dict[@"flag"]]) {
                [self changeWithID:model.mid withStatus:1];
                [self addLog:model.jsonBody reason:@"事件发送到服务器成功" requestUrl:model.requestUrl];
            } else {
                [self changeWithID:model.mid withStatus:2];
            }
        }else{
            [self changeWithID:model.mid withStatus:2];
        }
    }
    
}


- (NSString *)toJsonStringFromParam:(id)param {
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:param options:NSJSONWritingPrettyPrinted error:&error];
    NSString *jsonStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if ([self isNullString:jsonStr] && error == nil) {
        NSLog(@"转为的json字符串:=====%@",jsonStr);
        return jsonStr;
    }else {
        return @"";
    }
}


- (id)toArrayOrNSDictionaryFromData:(NSData *)jsonData{
    
    NSError *error = nil;
    
    id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&error];
    
    if (jsonObject != nil && error == nil) {
        
        return jsonObject;
        
    } else {
        
        return nil;
        
    }
    
}


- (void)addLog:(NSString *)jsonBody reason:(NSString *)reason requestUrl:(NSString *)requestUrl {
    @try {
        
         NSDictionary *event = [self toArrayOrNSDictionaryFromData:[jsonBody dataUsingEncoding:NSUTF8StringEncoding]];
        NSString *eventType = event[@"event_type"];
        
        if (![self isNullString:eventType] || [logEvent isEqualToString:eventType]) {
            return;
        }
        NSDate *now = [NSDate date];
        NSUInteger timeStamp = (NSUInteger)(([now timeIntervalSince1970]) * 1000);
       
        NSString *eventPhone = event[@"fields"][@"phone_no"];
        
        NSString *eventTime = [NSString stringWithFormat:@"%@",event[@"seq_tns"]];
        NSString *logStr = [NSString stringWithFormat:@"%@--%@--%@--%@",reason,eventType,eventTime,eventPhone];
        
        NSDictionary *fields = @{@"phone_no": eventPhone,
                                 @"eventType": eventType,
                                 @"eventTime": eventTime,
                                 @"log":logStr
                                 };
        
        
        NSDictionary *log = @{@"event_type": logEvent,
                                   @"seq_tns": @(timeStamp),
                                   @"fields": fields
                                   };
        
        
        [self insertToDB:[self toJsonStringFromParam:log] requestUrl:requestUrl priorityLevel:0];
        
    } @catch (NSException *exception) {
        NSLog(@"错误===%@",exception.description);
        
    } @finally {
        NSLog(@"finally");
    }
}


- (void)setupNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
}



#pragma mark - sessionDelegate
-(void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    
    // 采用信任证书方式执行
    if (challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust) {
        NSURLCredential *cre = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        // 调用block
        completionHandler(NSURLSessionAuthChallengeUseCredential,cre);
    }else {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling,nil);
    }
    
}


#pragma mark Background tasks

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    self.enterBackground = YES;
   
}

- (void)applicationWillEnterForeground:(NSNotification *)notification
{
    self.enterBackground = NO;
    [self upload];
    
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
