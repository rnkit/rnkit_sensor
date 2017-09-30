//
//  DataBaseHandle.h
//  RNKitSensor
//
//  Created by Snow on 2017/8/17.
//  Copyright © 2017年 SnowYang. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DataBaseModel;

@interface DataBaseHandle : NSObject

//单例类方法
+(instancetype)shareDataBase;

//插入数据(增)
-(void)insertModel:(DataBaseModel *)dbModel;

//批量更新
- (void)batchUpdeate:(NSArray *)modelArray;

//删除数据(删)
-(void)deleteWithStatus:(NSInteger)status repeatCount:(NSInteger)repeatCount;
//删除数据(删)
-(void)deleteWithStatus:(NSInteger)status;

//2.条件查
-(NSArray *)selectWithLimit:(NSInteger)limit;
-(NSArray *)selectWithRepeatCount:(NSInteger)repeatCount;

@end
