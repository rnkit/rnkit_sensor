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

//打开数据库
-(void)openDB;


//关闭数据库
-(void)closeDB;


//建表
-(void)createTable;


//插入数据(增)
-(void)insertModel:(DataBaseModel *)dbModel;


//修改数据(改)
-(void)updateWithID:(NSInteger)mid status:(NSInteger)status times:(NSInteger)times;

//批量更新
- (void)batchUpdeate:(NSArray *)modelArray;


//删除数据(删)
-(void)deleteWithStatus:(NSInteger)status;



//查找数据(查)

//1.全查
-(NSArray *)selectAll;


//2.条件查
-(NSArray *)selectWithLimit:(NSInteger)limit;

//重置id
-(void)resetId;

@end
