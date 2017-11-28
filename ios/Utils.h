//
//  Utils.h
//  RNKitSensor
//
//  Created by Snow on 2017/8/25.
//  Copyright © 2017年 SnowYang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Utils : NSObject

- (void)initial:(NSString *)appkey maxVolume:(NSInteger)maxVolume repeatTimes:(NSInteger)repeatTimes canLog:(BOOL)canLog;

- (void)insertToDB:(NSString *)jsonBody requestUrl:(NSString *)requestUrl priorityLevel:(NSInteger)level;

- (void)upload;

- (void)addLog:(NSString *)jsonBody reason:(NSString *)reason requestUrl:(NSString *)requestUrl;

@end
