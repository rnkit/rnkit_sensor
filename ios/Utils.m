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

static NSInteger maxVolumeNum = 0;

static NSString *appkeyStr;

static NSInteger repeatCount = 3;

@interface Utils ()

@property (nonatomic, strong) NSMutableArray *modelArray;
@property (nonatomic, assign) BOOL enterBackground;
@property (nonatomic, assign) NSInteger maxUploadNum;//有网情况下,上传失败,最多重复上传五次
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
    
    [[DataBaseHandle shareDataBase] openDB];
    [[DataBaseHandle shareDataBase] deleteWithStatus:1];
    
    if (queue == nil) {
        queue = dispatch_queue_create("io.rnkit.sensor", DISPATCH_QUEUE_SERIAL);
    }
    
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(queue, ^{
        __strong typeof(self) strongSelf = weakSelf;
        
        while (true) {
            
            if (strongSelf.enterBackground || strongSelf.maxUploadNum > 4) {
                
                [[DataBaseHandle shareDataBase] closeDB];
                break;
            }
            
            strongSelf.maxUploadNum++;
            
            NSArray *dbArray = [[DataBaseHandle shareDataBase] selectWithLimit:maxVolumeNum];
            
            if (dbArray.count > 0) {
                
                strongSelf.modelArray = [NSMutableArray array];
                
                for (DataBaseModel *model in dbArray) {
                    model.times += 1;
                    [strongSelf.modelArray addObject:model];
                    
                    NSDate *now = [NSDate date];
                    NSUInteger timeStamp = (NSUInteger)(([now timeIntervalSince1970]) * 1000);
                    NSDictionary *dict = @{@"timestamp":[NSString stringWithFormat:@"%lu",(unsigned long)timeStamp],
                                           @"distinct_id":[self idfa],
                                           @"bizType":@"B005",
                                           @"events":@[model.jsonBody]
                                           };
                    
                    [strongSelf requestWithJsonBody:[strongSelf toJsonStringFromParam:dict] requestUrl:model.requestUrl withID:model.mid];
                    
                }
                
                if (self.modelArray.count > 0) {
                    [[DataBaseHandle shareDataBase] batchUpdeate:self.modelArray];
                    int failRepeat = 0;
                    for (DataBaseModel *model in self.modelArray) {
                        if (model.times > repeatCount && model.priority > 0) {
                            failRepeat+=1;
                        }
                    }
                    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                    int preCount = [[defaults objectForKey:@"fail_repeatCount"] intValue];
                    int nowCount = preCount + failRepeat;
                    
                    [defaults setObject:@(nowCount) forKey:@"fail_repeatCount"];
                    [defaults synchronize];
                    
                    [[DataBaseHandle shareDataBase] deleteWithStatus:1 repeatCount:repeatCount];
                }
                
            } else {
                
                [[DataBaseHandle shareDataBase] resetId];
                
                [[DataBaseHandle shareDataBase] closeDB];
                
                break;
            }
        }
        
    });
    
}


- (void)changeWithID:(NSInteger)mid withStatus:(NSInteger)status {
    
    for (DataBaseModel *model in self.modelArray) {
        @autoreleasepool {
            if (mid == model.mid) {
               model.status = status;
            }
        }
    }
}


- (void)requestWithJsonBody:(NSString *)jsonBody requestUrl:(NSString *)requestUrl withID:(NSInteger)mid{
    
    @try {
        NSDate *now = [NSDate date];
        NSUInteger timeStamp = (NSUInteger)(([now timeIntervalSince1970]) * 1000);
        
        NSString *signatureString = [[self getMD5:[NSString stringWithFormat:@"%@%@%lu",jsonBody,appkeyStr,(unsigned long)timeStamp]] lowercaseString];
        
        NSURL *url = [NSURL URLWithString:requestUrl];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        request.HTTPMethod = @"POST";
        request.timeoutInterval = 10.0;
        
        [request setValue:@"true" forHTTPHeaderField:@"iscompress"];
        [request setValue:signatureString forHTTPHeaderField:@"content-md5"];
        [request setValue:[NSString stringWithFormat:@"%lu",(unsigned long)timeStamp] forHTTPHeaderField:@"content-timestamp"];
        
        request.HTTPBody = [LFCGzipUtillity gzipData:[jsonBody dataUsingEncoding:NSUTF8StringEncoding]];
        
        if (kIOS9) {
            NSURLSession *session = [NSURLSession sharedSession];
            NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                [self responseData:data error:error withID:mid];
            }];
            [task resume];
        } else {
            [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
                [self responseData:data error:connectionError withID:mid];
            }];
            
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


- (void)responseData:(NSData *)data error:(NSError *)error withID:(NSInteger)mid {
    
    if (error) {
        [self changeWithID:mid withStatus:2];
    } else {
        
        NSDictionary *dict = [self toArrayOrNSDictionaryFromData:data];
        if (dict) {
            if ([self isNullString:dict[@"flag"]] && [@"S" isEqualToString:dict[@"flag"]]) {
                [self changeWithID:mid withStatus:1];
                
            } else {
                [self changeWithID:mid withStatus:2];
            
            }
        }else{
            [self changeWithID:mid withStatus:2];
        }
    }
    
}


- (NSString *)toJsonStringFromParam:(id)param {
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:param options:NSJSONWritingPrettyPrinted error:&error];
    NSString *jsonStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if ([self isNullString:jsonStr] && error == nil) {
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


- (void)setupNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
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
