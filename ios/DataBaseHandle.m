//
//  DataBaseHandle.m
//  RNKitSensor
//
//  Created by Snow on 2017/8/17.
//  Copyright © 2017年 SnowYang. All rights reserved.
//

#import "DataBaseHandle.h"
#import <sqlite3.h>
#import "DataBaseModel.h"

static DataBaseHandle *handle = nil;

static sqlite3 *db = nil;


#define kDBpath @"rnkit-sensor.sqlite"

@implementation DataBaseHandle

+(instancetype)shareDataBase {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        handle = [[DataBaseHandle alloc] init];
    });
    return handle;
}

#pragma mark 打开数据库
-(void)openDB {
    if (db != nil) {
        NSLog(@"数据库已经打开");
        return;
    }
    
    NSString *docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *dbPath = [docPath stringByAppendingPathComponent:kDBpath];
    NSLog(@"数据库路径:%@",dbPath);
    
    int result = sqlite3_open(dbPath.UTF8String, &db);
    if (result == SQLITE_OK) {
        NSLog(@"数据库打开成功");
        if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"existTable"] intValue] == 0) {
            [self createTable];
        }
    } else {
        NSLog(@"数据库打开失败");
    }
}


#pragma mark 关闭数据库
-(void)closeDB {
    int reselt = sqlite3_close(db);
    if (reselt == SQLITE_OK) {
        NSLog(@"数据库关闭成功");
        db = nil;
    } else {
        NSLog(@"数据库关闭失败");
    }

}


#pragma mark 建表
-(void)createTable {
    
    NSString *sqlStr = @"CREATE TABLE IF NOT EXISTS RNKitSensor (mid BIGINT PRIMARY KEY  AUTOINCREMENT  NOT NULL , jsonBody TEXT,requestUrl VARCHAR(254), timeStamp BIGINT, times INTEGER,status INTEGER)";
    
    int result = sqlite3_exec(db, sqlStr.UTF8String, NULL, NULL, NULL);
    if (result == SQLITE_OK) {
        NSLog(@"建表成功");
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:@(1) forKey:@"existTable"];
        [defaults synchronize];
    }else{
        NSLog(@"建表失败");
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:@(0) forKey:@"existTable"];
        [defaults synchronize];
    }
}


#pragma mark 插入数据(增)
-(void)insertModel:(DataBaseModel *)dbModel {
    
    NSString *insertSql = [NSString stringWithFormat:@"INSERT INTO RNKitSensor (jsonBody,requestUrl,timeStamp,times,status) VALUES ('%@','%@','%lu','%ld','%ld')",dbModel.jsonBody,dbModel.requestUrl,dbModel.timeStamp,dbModel.times,dbModel.status];
    
    int result = sqlite3_exec(db, insertSql.UTF8String, NULL, NULL, NULL);
    if (result == SQLITE_OK) {
        NSLog(@"添加成功");
    }else{
        NSLog(@"添加失败");
    }
}


#pragma mark  修改数据(改)
-(void)updateWithID:(NSUInteger)mid status:(NSInteger)status times:(NSInteger)times {
    
    NSString *updateSql = [NSString stringWithFormat:@"UPDATE RNKitSensor SET status = '%ld', times = '%ld' WHERE mid = '%lu'",status,times,mid];
    
    int result = sqlite3_exec(db, updateSql.UTF8String, NULL, NULL, NULL);
    
    if (result == SQLITE_OK) {
        NSLog(@"修改成功");
    }else{
        NSLog(@"修改失败");
    }

}



#pragma mark - 批量更新
- (void)batchUpdeate:(NSArray *)modelArray {

    NSMutableString *str = [NSMutableString string];
    for (DataBaseModel *model in modelArray) {
        
        [str appendFormat:@"(%lu,'%@','%@','%lu','%ld','%ld'),",(unsigned long)model.mid,model.jsonBody,model.requestUrl,(unsigned long)model.timeStamp,(long)model.times,(long)model.status];
    }
    //切记最后一个参数木有逗号
    str = ([str substringToIndex:str.length - 1]).mutableCopy;

    NSString *updateSql = [NSString stringWithFormat:@"REPLACE INTO RNKitSensor (mid,jsonBody,requestUrl,timeStamp,times,status) values %@",str];
    
    int result = sqlite3_exec(db, updateSql.UTF8String, NULL, NULL, NULL);
    if (result == SQLITE_OK) {
        NSLog(@"修改成功");
    }else{
        NSLog(@"修改失败");
    }

    
}

#pragma mark 删除数据(删)
-(void)deleteWithStatus:(NSInteger)status {
    
    NSString *deleteSql = [NSString stringWithFormat:@"DELETE FROM RNKitSensor WHERE status = '%ld'",status];
    
    int result = sqlite3_exec(db, deleteSql.UTF8String, NULL, NULL, NULL);
    
    if (result == SQLITE_OK) {
        NSLog(@"删除成功");
    }else{
        NSLog(@"删除失败");
    }

}


#pragma mark  全查
-(NSArray *)selectAll {
    
    NSString *selectSql = @"SELECT * FROM RNKitSensor";
    
    return [self selectResults:selectSql isSelectAll:YES selectWithParameter:-1];
    
    
}


#pragma mark 条件查
-(NSArray *)selectWithStatus:(NSInteger)status {
    
    NSString *selectSql = @"SELECT * FROM RNKitSensor WHERE status = ?";
    
    return [self selectResults:selectSql isSelectAll:NO selectWithParameter:status];
    
}


- (NSArray *)selectResults:(NSString *)selectSql isSelectAll:(BOOL)isAll selectWithParameter:(NSInteger)parameter {
    
    NSMutableArray *modelArray = nil;
    
    sqlite3_stmt *stmt = nil;
    
    int result = sqlite3_prepare_v2(db, selectSql.UTF8String, -1, &stmt, NULL);
    
    if (result == SQLITE_OK) {
        modelArray = [NSMutableArray array];
        
        isAll ? NSLog(@"查询全部") : sqlite3_bind_int(stmt,1,(int)parameter);
        
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            NSUInteger mid = sqlite3_column_double(stmt, 0);
            NSString *jsonBody = [NSString stringWithUTF8String:(const char *) sqlite3_column_text(stmt, 1)];
            NSString *requestUrl = [NSString stringWithUTF8String:(const char *) sqlite3_column_text(stmt, 2)];
            NSUInteger timeStamp = sqlite3_column_double(stmt, 3);
            NSInteger times = sqlite3_column_int(stmt, 4);
            NSInteger status = sqlite3_column_int(stmt, 5);
            
            DataBaseModel *model = [DataBaseModel new];
            model.mid = mid;
            model.jsonBody = jsonBody;
            model.requestUrl = requestUrl;
            model.timeStamp = timeStamp;
            model.times = times;
            model.status = status;
            
            [modelArray addObject:model];
            
        }
    }
    
    sqlite3_finalize(stmt);
    for (DataBaseModel *model in modelArray) {
        NSLog(@"mid:%ld,jsonBody:%@,requestUrl:%@,timeStamp:%lu,times:%ld,status:%ld",model.mid,model.jsonBody,model.requestUrl,model.timeStamp,model.times,model.status);
    }
    
    return modelArray;

}

#pragma mark - 重置id
-(void)resetId {
    
    NSString *resetSql = @"TRUNCATE TABLE RNKitSensor";
    
    int result = sqlite3_exec(db, resetSql.UTF8String, NULL, NULL, NULL);
    NSLog(@"result值:%d",result);
    if (result == SQLITE_OK) {
        NSLog(@"重制id成功");
    }else{
        NSLog(@"重置id失败");
    }
}

@end
