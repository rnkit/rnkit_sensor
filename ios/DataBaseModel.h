//
//  DataBaseModel.h
//  RNKitSensor
//
//  Created by Snow on 2017/8/17.
//  Copyright © 2017年 SnowYang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DataBaseModel : NSObject

@property (nonatomic, assign) NSInteger mid; //表id
@property (nonatomic, copy) NSString *jsonBody; //json字符串
@property (nonatomic, copy) NSString *requestUrl; //请求地址
@property (nonatomic, assign) NSUInteger timeStamp; //存储进数据库的时间戳
@property (nonatomic, assign) NSInteger times; //向后台发送的次数
@property (nonatomic, assign) NSInteger status; //0:初始状态,1:上传成功,2:上传失败
@property (nonatomic, assign) NSInteger priority; //优先级:数值越小,优先级越高,且<=0为通讯录的优先级
@end
