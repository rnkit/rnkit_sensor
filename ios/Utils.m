//
//  Utils.m
//  RNKitSensor
//
//  Created by Snow on 2017/8/25.
//  Copyright © 2017年 SnowYang. All rights reserved.
//

#import "Utils.h"

static NSInteger maxVolumeNum = 0;

static NSString *appkeyStr;

@implementation Utils

+ (void)setMaxVolume:(NSInteger)maxVolume {
    maxVolumeNum = maxVolume;
}

+ (NSInteger)getMaxVolume {
    return maxVolumeNum;
}

+ (void)setAppkey:(NSString *)appkey {
    appkeyStr = appkey;
}

+ (NSString *)getAppkey {
    return appkeyStr;
}


@end
