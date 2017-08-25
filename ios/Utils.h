//
//  Utils.h
//  RNKitSensor
//
//  Created by Snow on 2017/8/25.
//  Copyright © 2017年 SnowYang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Utils : NSObject

+ (void)setMaxVolume:(NSInteger)maxVolume;
+ (NSInteger)getMaxVolume;

+ (void)setAppkey:(NSString *)appkey;
+ (NSString *)getAppkey;

@end
