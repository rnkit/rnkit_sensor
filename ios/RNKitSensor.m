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
#else
#import "RCTConvert.h"
#import "RCTLog.h"
#endif

#import "Utils.h"

@interface RNKitSensor ()

@property (nonatomic, strong) Utils *utils;

@end

@implementation RNKitSensor

RCT_EXPORT_MODULE();

/**
 * 初始化
 *
 * @param appKey      服务器分配的appKey
 * @param maxVolume   一次最大上传的埋点条数
 * @param repeatTimes 最大尝试次数
 */
RCT_EXPORT_METHOD(initial:(NSString *)appkey maxVolume:(NSInteger)maxVolume repeatTimes:(NSInteger)repeatTimes)
{
    [self.utils initial:appkey maxVolume:maxVolume repeatTimes:repeatTimes];
}


/**
 * 存储到本地数据库
 *
 * @param jsonBody   埋点数据
 * @param requestUrl 请求的Url
 * @param level   这条埋点数据的优先级
 */

RCT_EXPORT_METHOD(save:(NSString *)jsonBody requestUrl:(NSString *)requestUrl priorityLevel:(NSInteger)level)
{
    [self.utils insertToDB:jsonBody requestUrl:requestUrl priorityLevel:level];
}


/**
 * 检查本地是否有没有发送的埋点
 */
RCT_EXPORT_METHOD(check)
{
    [self.utils upload];
   
}



/**
 * 达到失败次数上限删除数量
 */
RCT_REMAP_METHOD(getFailCount,
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
    int count = [[[NSUserDefaults standardUserDefaults] objectForKey:@"fail_repeatCount"] intValue];
    RCTLogInfo(@"最大上传次数失败次数====%d",count);
    if (count >= 0) {
        resolve(count);
    } else {
        reject(@"无超过最大上传次数的数据");
    }
}


- (Utils *)utils {
    if (!_utils) {
        _utils = [Utils new];
    }
    return _utils;
}


@end
